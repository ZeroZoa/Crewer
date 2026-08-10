package NPJ.Crewer.evaluation;

import NPJ.Crewer.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EvaluationRepository extends JpaRepository<Evaluation, Long> {
    
    List<Evaluation> findByGroupFeed(GroupFeed groupFeed);
    
    List<Evaluation> findByEvaluated(Member evaluated);
    
    Optional<Evaluation> findByEvaluatorAndEvaluatedAndGroupFeed(
        Member evaluator, Member evaluated, GroupFeed groupFeed);
    
    @Query("SELECT e FROM Evaluation e WHERE e.groupFeed = :groupFeed AND e.evaluator = :evaluator")
    List<Evaluation> findByGroupFeedAndEvaluator(@Param("groupFeed") GroupFeed groupFeed, @Param("evaluator") Member evaluator);
    
    // 특정 사용자가 특정 그룹 피드를 평가했는지 확인
    @Query("SELECT COUNT(e) > 0 FROM Evaluation e WHERE e.groupFeed.id = :groupFeedId AND e.evaluator.id = :evaluatorId")
    boolean existsByGroupFeedIdAndEvaluatorId(@Param("groupFeedId") Long groupFeedId, @Param("evaluatorId") Long evaluatorId);
    
    // 사용자가 평가 완료한 그룹 피드 ID 목록 조회 (N+1 방지용)
    @Query("SELECT e.groupFeed.id FROM Evaluation e WHERE e.evaluator.id = :evaluatorId AND e.groupFeed.id IN :groupFeedIds")
    List<Long> findCompletedGroupFeedIdsByEvaluator(@Param("groupFeedIds") List<Long> groupFeedIds, @Param("evaluatorId") Long evaluatorId);
}
