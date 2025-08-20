package NPJ.Crewer.running;

import NPJ.Crewer.running.dto.response.RankingResponse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RunningRepository extends JpaRepository<RunningRecord, Long> {

    //사용자의 러닝 기록을 생성일(createdAt) 기준으로 내림차순 조회
    List<RunningRecord> findAllByRunnerIdOrderByCreatedAtDesc(Long runnerId);

    @Query(value = """
    WITH distance_categories AS (
        SELECT
            rr.id,
            rr.runner_id,
            rr.total_distance,
            rr.total_seconds,
            rr.created_at,
            CASE
                WHEN rr.total_distance >= 1000 AND rr.total_distance < 3000 THEN '1-3km'
                WHEN rr.total_distance >= 3000 AND rr.total_distance < 5000 THEN '3-5km'
                WHEN rr.total_distance >= 5000 AND rr.total_distance < 10000 THEN '5-10km'
                WHEN rr.total_distance >= 10000 AND rr.total_distance < 21000 THEN '10-21km'
                WHEN rr.total_distance >= 21000 THEN '21km~'
                ELSE 'other'
            END AS distance_category
        FROM
            running_record rr
        WHERE
            rr.created_at >= NOW() - INTERVAL '1 month'
    ),
    user_best_records AS (
        SELECT
            *,
            ROW_NUMBER() OVER(PARTITION BY runner_id, distance_category ORDER BY (total_seconds * 1000.0 / total_distance) ASC) as rn
        FROM
            distance_categories
        WHERE
            distance_category != 'other'
    ),
    ranked_records AS (
        SELECT
            *,
            ROW_NUMBER() OVER(PARTITION BY distance_category ORDER BY (total_seconds * 1000.0 / total_distance) ASC) as ranking
        FROM
            user_best_records
        WHERE
            rn = 1
    )
    SELECT
        id AS recordId,
        runner_id AS runnerId,
        total_distance AS totalDistance,
        total_seconds AS totalSeconds,
        created_at AS createdAt,
        distance_category AS distanceCategory,
        ranking
    FROM
        ranked_records
    ORDER BY
        distance_category, ranking
    """, nativeQuery = true)
    List<RankingResponse> findRankings();
}
