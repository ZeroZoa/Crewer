package NPJ.Crewer.like;

import NPJ.Crewer.feed.Feed;
import NPJ.Crewer.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface LikeFeedRepository extends JpaRepository<LikeFeed, Long> {

    //특정 사용자가 특정 피드를 좋아요 했는지 확인
    boolean existsByMemberIdAndFeedId(Long memberId, Long feedId);

    //특정 사용자의 좋아요 삭제
    void deleteByMemberIdAndFeedId(Long memberId, Long feedId);

    //특정 사용자의 특정 피드 좋아요 조회
    Optional<LikeFeed> findByFeedAndMember(Feed feed, Member member);

    //특정 피드의 좋아요 개수 조회
    long countByFeedId(Long feedId);

    boolean existsByMemberAndFeed(Member member, Feed feed);
}