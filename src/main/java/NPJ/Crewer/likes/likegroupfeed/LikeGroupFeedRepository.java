package NPJ.Crewer.likes.likegroupfeed;

import NPJ.Crewer.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LikeGroupFeedRepository extends JpaRepository<LikeGroupFeed, Long> {
    //특정 사용자의 특정 피드 좋아요 조회
    Optional<LikeGroupFeed> findByGroupFeedAndLiker(GroupFeed groupFeed, Member liker);

    //특정 피드의 좋아요 개수 조회
    long countByGroupFeedId(Long groupFeedId);

    //피드와 사용자를 검색하여 좋아요를 눌렀는지 확인
    boolean existsByGroupFeedAndLiker(GroupFeed groupFeed, Member liker);

    //좋아요한 피드 최신순으로 불러오기
    List<LikeGroupFeed> findByLikerOrderByCreatedAtDesc(Member liker);

    // 특정 피드의 모든 좋아요 삭제
    void deleteByGroupFeedId(Long groupFeedId);
}
