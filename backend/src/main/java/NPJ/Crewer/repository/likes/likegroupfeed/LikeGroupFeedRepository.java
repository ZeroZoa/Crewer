package NPJ.Crewer.repository.likes.likegroupfeed;

import NPJ.Crewer.domain.likes.likegroupfeed.LikeGroupFeed;

import NPJ.Crewer.domain.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.domain.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LikeGroupFeedRepository extends JpaRepository<LikeGroupFeed, Long> {
    //특정 사용자의 특정 피드 좋아요 조회
    Optional<LikeGroupFeed> findByGroupFeedAndLiker(GroupFeed groupFeed, Member liker);

    //특정 피드의 좋아요 개수 조회
    long countByGroupFeedId(Long groupFeedId);

    //좋아요한 피드 최신순으로 불러오기
    List<LikeGroupFeed> findByLikerOrderByCreatedAtDesc(Member liker);
}
