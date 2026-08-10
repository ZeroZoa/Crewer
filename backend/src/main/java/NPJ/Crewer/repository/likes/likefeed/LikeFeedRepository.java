package NPJ.Crewer.repository.likes.likefeed;

import NPJ.Crewer.domain.likes.likefeed.LikeFeed;

import NPJ.Crewer.domain.feeds.feed.Feed;
import NPJ.Crewer.domain.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LikeFeedRepository extends JpaRepository<LikeFeed, Long> {

    //특정 사용자의 특정 피드 좋아요 조회
    Optional<LikeFeed> findByFeedAndLiker(Feed feed, Member liker);

    //특정 피드의 좋아요 개수 조회
    long countByFeedId(Long feedId);

    //좋아요한 피드 최신순으로 불러오기
    List<LikeFeed> findByLikerOrderByCreatedAtDesc(Member liker);
}
