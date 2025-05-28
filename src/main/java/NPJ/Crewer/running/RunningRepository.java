package NPJ.Crewer.running;

import NPJ.Crewer.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RunningRepository extends JpaRepository<RunningRecord, Long> {

    //사용자의 러닝 기록을 생성일(createdAt) 기준으로 내림차순 조회
    List<RunningRecord> findAllByRunnerIdOrderByCreatedAtDesc(Long runnerId);

    //총 거리가 특정 거리 이상인 기록 중, 사용자별 최소 페이스(pace)를 기준으로 랭킹 조회
//    @Query("SELECT r.runner.nickname AS runnerNickname, MIN(r.pace) AS pace " +
//            "FROM RunningRecord r " +
//            "WHERE r.totalDistance >= :minDistance " +
//            "GROUP BY r.runner.nickname " +
//            "ORDER BY MIN(r.pace) ASC")
//    List<RunnerPaceRanking> findRunnerPaceRanking(@Param("minDistance") double minDistance);

}
