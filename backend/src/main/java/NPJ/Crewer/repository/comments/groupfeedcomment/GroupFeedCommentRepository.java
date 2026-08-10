package NPJ.Crewer.repository.comments.groupfeedcomment;

import NPJ.Crewer.domain.comments.groupfeedcomment.GroupFeedComment;
import NPJ.Crewer.domain.feeds.feed.Feed;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GroupFeedCommentRepository extends JpaRepository<GroupFeedComment, Long> {
    //Feed id를 통해 해당 피드 Comment 불러오기
    List<GroupFeedComment> findByGroupFeedId(Long groupFeedId);
}
