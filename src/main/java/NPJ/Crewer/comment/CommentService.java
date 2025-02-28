package NPJ.Crewer.comment;

import NPJ.Crewer.comment.dto.CommentCreateDTO;
import NPJ.Crewer.comment.dto.CommentResponseDTO;
import NPJ.Crewer.feed.Feed;
import NPJ.Crewer.feed.FeedRepository;
import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@RequiredArgsConstructor
@Service
public class CommentService {
    private final CommentRepository commentRepository;
    private final FeedRepository feedRepository;

    //Comment 생성
    @Transactional
    public CommentResponseDTO createComment(Long feedId, CommentCreateDTO commentCreateDTO, Member member){
        //Comment를 작성할 Feed 조회 (없으면 예외 발생)
        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("피드를 찾을 수 없습니다."));


        Comment comment = Comment.builder()
                .content(commentCreateDTO.getContent())
                .feed(feed)
                .author(member)
                .build();

        Comment savedComment = commentRepository.save(comment);

        // 4️⃣ DTO 변환 후 반환
        return new CommentResponseDTO(savedComment.getId(), savedComment.getContent(),
                savedComment.getAuthor().getNickname(), savedComment.getCreatedAt());
    }

    //댓글 불러오기
    @Transactional(readOnly = true)
    public List<CommentResponseDTO> getCommentsByFeed(Long feedId) {
        List<Comment> comments = commentRepository.findByFeedId(feedId);

        //DTO 변환하여 반환 (Hibernate 프록시 문제 해결)
        return comments.stream()
                .map(comment -> new CommentResponseDTO(
                        comment.getId(),
                        comment.getContent(),
                        comment.getAuthor().getNickname(), // Member 대신 닉네임만 반환
                        comment.getCreatedAt()
                ))
                .toList();
    }

    //댓글 삭제하기
    @Transactional
    public void deleteComment(Long commentId, Member member){
        //댓글을 삭제할 Feed 조회 (없으면 예외 발생)
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new IllegalArgumentException("댓글을 찾을 수 없습니다."));

        //피드를 삭제 권한 확인 (작성자만 가능)
        if (!comment.getAuthor().equals(member)) {
            throw new AccessDeniedException("본인이 작성한 댓글만 삭제할 수 있습니다.");
        }

        commentRepository.delete(comment);

    }
}
