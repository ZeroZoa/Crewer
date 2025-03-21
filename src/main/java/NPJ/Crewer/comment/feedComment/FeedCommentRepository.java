package NPJ.Crewer.comment.feedComment;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FeedCommentRepository extends JpaRepository<FeedComment, Long> {
    //Feed id를 통해 해당 피드 Comment 불러오기
    List<FeedComment> findByFeedId(Long feedId);

    // 특정 피드의 모든 댓글 삭제
    void deleteByFeedId(Long feedId);
}
