package NPJ.Crewer.repository.comments.feedcomment;

import NPJ.Crewer.domain.comments.feedcomment.FeedComment;
import NPJ.Crewer.domain.feeds.feed.Feed;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FeedCommentRepository extends JpaRepository<FeedComment, Long> {
    //Feed id를 통해 해당 피드 Comment 불러오기
    List<FeedComment> findByFeedId(Long feedId);
}
