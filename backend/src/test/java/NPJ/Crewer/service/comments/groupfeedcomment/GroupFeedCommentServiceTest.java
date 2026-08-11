package NPJ.Crewer.service.comments.groupfeedcomment;

import NPJ.Crewer.domain.comments.groupfeedcomment.GroupFeedComment;
import NPJ.Crewer.domain.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.domain.member.Member;
import NPJ.Crewer.repository.comments.groupfeedcomment.GroupFeedCommentRepository;
import NPJ.Crewer.repository.feeds.groupfeed.GroupFeedRepository;
import NPJ.Crewer.repository.member.MemberRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GroupFeedCommentServiceTest {

    @Mock
    private GroupFeedCommentRepository groupFeedCommentRepository;
    @Mock
    private GroupFeedRepository groupFeedRepository;
    @Mock
    private MemberRepository memberRepository;

    @InjectMocks
    private GroupFeedCommentService groupFeedCommentService;

    private Member author;
    private Member stranger;
    private GroupFeedComment comment;

    @BeforeEach
    void setUp() {
        author = mock(Member.class);
        stranger = mock(Member.class);
        GroupFeed groupFeed = mock(GroupFeed.class);
        comment = GroupFeedComment.builder()
                .id(1L)
                .content("댓글 내용")
                .groupFeed(groupFeed)
                .author(author)
                .build();
    }

    @Test
    void 작성자는_자신의_댓글을_삭제할_수_있다() {
        when(memberRepository.findById(1L)).thenReturn(Optional.of(author));
        when(groupFeedCommentRepository.findById(1L)).thenReturn(Optional.of(comment));

        groupFeedCommentService.deleteComment(1L, 1L);

        verify(groupFeedCommentRepository).delete(comment);
    }

    @Test
    void 작성자가_아니면_댓글을_삭제할_수_없다() {
        when(memberRepository.findById(2L)).thenReturn(Optional.of(stranger));
        when(groupFeedCommentRepository.findById(1L)).thenReturn(Optional.of(comment));

        assertThatThrownBy(() -> groupFeedCommentService.deleteComment(1L, 2L))
                .isInstanceOf(AccessDeniedException.class);

        verify(groupFeedCommentRepository, never()).delete(any());
    }
}
