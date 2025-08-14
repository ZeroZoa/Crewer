package NPJ.Crewer.running;

import NPJ.Crewer.running.dto.RankingResponseDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RunningRepository extends JpaRepository<RunningRecord, Long> {

    //사용자의 러닝 기록을 생성일(createdAt) 기준으로 내림차순 조회
    List<RunningRecord> findAllByRunnerIdOrderByCreatedAtDesc(Long runnerId);

    @Query(value = """
    -- 랭킹을 거리별로 나누어 집계
    WITH distance_categories AS (
        SELECT
            running_record.*,
            member.nickname,
            CASE
                WHEN running_record.total_distance >= 1000 AND running_record.total_distance < 3000 THEN '1-3km'
                WHEN running_record.total_distance >= 3000 AND running_record.total_distance < 5000 THEN '3-5km'
                WHEN running_record.total_distance >= 5000 AND running_record.total_distance < 10000 THEN '5-10km'
                WHEN running_record.total_distance >= 10000 AND running_record.total_distance < 21000 THEN '10-21km'
                WHEN running_record.total_distance >= 21000 THEN '21km~'
                ELSE 'other'
            END AS distance_category
        FROM
            running_record
        JOIN
            member ON running_record.runner_id = member.id
        WHERE
            running_record.created_at >= NOW() - INTERVAL '1 month'
    ),
    user_best_records AS (
        -- 이 부분이 핵심입니다. 사용자별, 구간별로 가장 빠른 기록 1개만 선택합니다.
        SELECT
            *,
            ROW_NUMBER() OVER(PARTITION BY runner_id, distance_category ORDER BY (total_seconds * 1000.0 / total_distance) ASC) as rn
        FROM
            distance_categories
        WHERE
            distance_category != 'other'
    ),
    ranked_records AS (
        -- 위에서 뽑은 각 사용자의 최고 기록들을 가지고 최종 랭킹을 매깁니다.
        SELECT
            *,
            ROW_NUMBER() OVER(PARTITION BY distance_category ORDER BY (total_seconds * 1000.0 / total_distance) ASC) as ranking
        FROM
            user_best_records
        WHERE
            rn = 1 -- rn = 1은 각 사용자의 구간별 최고 기록을 의미합니다.
    )
    SELECT
        id AS recordId,
        nickname AS runnerNickname,
        total_distance AS totalDistance,
        total_seconds AS totalSeconds,
        created_at AS createdAt,
        distance_category AS distanceCategory,
        ranking
    FROM
        ranked_records
    ORDER BY
        distance_category, ranking;
    """, nativeQuery = true)
    List<RankingResponseDTO> findRankings();


}
