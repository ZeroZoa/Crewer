package NPJ.Crewer.comment.groupFeedComment;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GroupFeedCommentRepository extends JpaRepository<GroupFeedComment, Long> {
    //Feed id를 통해 해당 피드 Comment 불러오기
    List<GroupFeedComment> findByGroupFeedId(Long groupFeedId);

    // 특정 피드의 모든 댓글 삭제
    void deleteByGroupFeedId(Long groupFeedId);
}
