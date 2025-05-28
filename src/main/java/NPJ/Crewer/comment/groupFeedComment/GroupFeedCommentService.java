package NPJ.Crewer.comment.groupFeedComment;

import NPJ.Crewer.comment.feedComment.dto.FeedCommentResponseDTO;
import NPJ.Crewer.comment.groupFeedComment.dto.GroupFeedCommentCreateDTO;
import NPJ.Crewer.feed.groupFeed.GroupFeed;
import NPJ.Crewer.feed.groupFeed.GroupFeedRepository;
import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@RequiredArgsConstructor
@Service
public class GroupFeedCommentService {
    private final GroupFeedCommentRepository groupFeedCommentRepository;
    private final GroupFeedRepository groupFeedRepository;

    //GroupFeedComment 생성
    @Transactional
    public FeedCommentResponseDTO createComment(Long groupFeedId, GroupFeedCommentCreateDTO groupFeedCommentCreateDTO, Member member){
        //Comment를 작성할 Feed 조회 (없으면 예외 발생)
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("GroupFeed를 찾을 수 없습니다."));

        //GroupFeedComment 생성
        GroupFeedComment groupFeedComment = GroupFeedComment.builder()
                .content(groupFeedCommentCreateDTO.getContent())
                .groupFeed(groupFeed)
                .author(member)
                .build();

        GroupFeedComment savedGroupFeedComment = groupFeedCommentRepository.save(groupFeedComment);

        //DTO 변환 후 반환
        return new FeedCommentResponseDTO(savedGroupFeedComment.getId(), savedGroupFeedComment.getContent(),
                savedGroupFeedComment.getAuthor().getNickname(), savedGroupFeedComment.getCreatedAt());
    }


    //GroupFeedComment 조회
    @Transactional(readOnly = true)
    public List<FeedCommentResponseDTO> getCommentsByGroupFeed(Long groupFeedId) {
        List<GroupFeedComment> groupFeedComments = groupFeedCommentRepository.findByGroupFeedId(groupFeedId);

        //DTO 변환하여 반환 (Hibernate 프록시 문제 해결)
        return groupFeedComments.stream()
                .map(groupFeedComment -> new FeedCommentResponseDTO(
                        groupFeedComment.getId(),
                        groupFeedComment.getContent(),
                        groupFeedComment.getAuthor().getNickname(), // Member 대신 닉네임만 반환
                        groupFeedComment.getCreatedAt()
                ))
                .toList();
    }

    //댓글 삭제하기
    @Transactional
    public void deleteComment(Long commentId, Member member){
        //댓글을 삭제할 Feed 조회 (없으면 예외 발생)
        GroupFeedComment groupFeedComment = groupFeedCommentRepository.findById(commentId)
                .orElseThrow(() -> new IllegalArgumentException("댓글을 찾을 수 없습니다."));

        //피드를 삭제 권한 확인 (작성자만 가능)
        if (!groupFeedComment.getAuthor().equals(member)) {
            throw new AccessDeniedException("본인이 작성한 댓글만 삭제할 수 있습니다.");
        }

        groupFeedCommentRepository.delete(groupFeedComment);

    }
}
