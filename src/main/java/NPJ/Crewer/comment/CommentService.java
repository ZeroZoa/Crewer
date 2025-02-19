package NPJ.Crewer.comment;

import NPJ.Crewer.feed.Feed;
import NPJ.Crewer.feed.FeedRepository;
import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@RequiredArgsConstructor
@Service
public class CommentService {
    private final CommentRepository commentRepository;
    private final FeedRepository feedRepository;

    @Transactional
    public Comment createComment(Long feedId, String content, Member member) {
        if (member == null) {
            throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");
        }
        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("해당 피드를 찾을 수 없습니다."));

        Comment comment = Comment.builder()
                .content(content)
                .author(member)
                .feed(feed)
                .build();

        return commentRepository.save(comment);
    }

    @Transactional(readOnly = true)
    public List<Comment> getCommentsByFeed(Long feedId) {
        return commentRepository.findByFeedId(feedId);
    }

    @Transactional
    public void deleteComment(Long commentId, String username) {
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new IllegalArgumentException("해당 댓글을 찾을 수 없습니다."));

        if (!comment.getAuthor().getUsername().equals(username)) {
            throw new IllegalArgumentException("댓글 삭제 권한이 없습니다.");
        }

        commentRepository.delete(comment);
    }
}
