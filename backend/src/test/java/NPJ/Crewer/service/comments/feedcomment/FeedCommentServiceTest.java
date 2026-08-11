package NPJ.Crewer.service.comments.feedcomment;

import NPJ.Crewer.domain.comments.feedcomment.FeedComment;
import NPJ.Crewer.domain.feeds.feed.Feed;
import NPJ.Crewer.domain.member.Member;
import NPJ.Crewer.repository.comments.feedcomment.FeedCommentRepository;
import NPJ.Crewer.repository.feeds.feed.FeedRepository;
import NPJ.Crewer.repository.member.MemberRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FeedCommentServiceTest {

    @Mock
    private FeedCommentRepository feedCommentRepository;
    @Mock
    private FeedRepository feedRepository;
    @Mock
    private MemberRepository memberRepository;

    @InjectMocks
    private FeedCommentService feedCommentService;

    private Member author;
    private Member stranger;
    private Feed feed;
    private FeedComment comment;

    @BeforeEach
    void setUp() {
        author = mock(Member.class);
        stranger = mock(Member.class);
        feed = mock(Feed.class);
        comment = FeedComment.builder()
                .id(1L)
                .content("댓글 내용")
                .feed(feed)
                .author(author)
                .build();
    }

    @Test
    void 작성자는_자신의_댓글을_삭제할_수_있다() {
        when(memberRepository.findById(1L)).thenReturn(Optional.of(author));
        when(feedCommentRepository.findById(1L)).thenReturn(Optional.of(comment));

        feedCommentService.deleteComment(1L, 1L);

        verify(feedCommentRepository).delete(comment);
    }

    @Test
    void 작성자가_아니면_댓글을_삭제할_수_없다() {
        when(memberRepository.findById(2L)).thenReturn(Optional.of(stranger));
        when(feedCommentRepository.findById(1L)).thenReturn(Optional.of(comment));

        assertThatThrownBy(() -> feedCommentService.deleteComment(1L, 2L))
                .isInstanceOf(AccessDeniedException.class);

        verify(feedCommentRepository, never()).delete(any());
    }

    @Test
    void 존재하지_않는_댓글은_삭제할_수_없다() {
        when(memberRepository.findById(1L)).thenReturn(Optional.of(author));
        when(feedCommentRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> feedCommentService.deleteComment(99L, 1L))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
