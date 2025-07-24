package NPJ.Crewer.comment.feedComment;

import NPJ.Crewer.comment.feedComment.dto.FeedCommentCreateDTO;
import NPJ.Crewer.comment.feedComment.dto.FeedCommentResponseDTO;
import NPJ.Crewer.feed.normalFeed.Feed;
import NPJ.Crewer.feed.normalFeed.FeedRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@RequiredArgsConstructor
@Service
public class FeedCommentService {
    private final FeedCommentRepository feedCommentRepository;
    private final FeedRepository feedRepository;
    private final MemberRepository memberRepository;

    //Comment 생성
    @Transactional
    public FeedCommentResponseDTO createComment(Long feedId, FeedCommentCreateDTO feedCommentCreateDTO, Long memberId){
        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        //Comment를 작성할 Feed 조회 (없으면 예외 발생)
        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("피드를 찾을 수 없습니다."));

        //FeedComment 생성
        FeedComment feedComment = FeedComment.builder()
                .content(feedCommentCreateDTO.getContent())
                .feed(feed)
                .author(member)
                .build();

        FeedComment savedFeedComment = feedCommentRepository.save(feedComment);

        //DTO 변환 후 반환
        return new FeedCommentResponseDTO(savedFeedComment.getId(), savedFeedComment.getContent(),
                savedFeedComment.getAuthor().getNickname(), savedFeedComment.getCreatedAt());
    }

    //FeedComment 불러오기
    @Transactional(readOnly = true)
    public List<FeedCommentResponseDTO> getCommentsByFeed(Long feedId) {
        List<FeedComment> feedComments = feedCommentRepository.findByFeedId(feedId);

        //DTO 변환하여 반환 (Hibernate 프록시 문제 해결)
        return feedComments.stream()
                .map(feedComment -> new FeedCommentResponseDTO(
                        feedComment.getId(),
                        feedComment.getContent(),
                        feedComment.getAuthor().getNickname(), // Member 대신 닉네임만 반환
                        feedComment.getCreatedAt()
                ))
                .toList();
    }

    //FeedComment 삭제하기
    @Transactional
    public void deleteComment(Long commentId, Long memberId){
        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        //댓글을 삭제할 Feed 조회 (없으면 예외 발생)
        FeedComment feedComment = feedCommentRepository.findById(commentId)
                .orElseThrow(() -> new IllegalArgumentException("댓글을 찾을 수 없습니다."));

        //피드를 삭제 권한 확인 (작성자만 가능)
        if (!feedComment.getAuthor().equals(member)) {
            throw new AccessDeniedException("본인이 작성한 댓글만 삭제할 수 있습니다.");
        }

        feedCommentRepository.delete(feedComment);

    }
}
