package NPJ.Crewer.service.feeds.groupfeed;

import NPJ.Crewer.domain.chat.chatroom.ChatRoom;
import NPJ.Crewer.domain.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.domain.feeds.groupfeed.GroupFeedStatus;
import NPJ.Crewer.domain.member.Member;
import NPJ.Crewer.repository.chat.chatparticipant.ChatParticipantRepository;
import NPJ.Crewer.repository.chat.chatmessage.ChatMessageRepository;
import NPJ.Crewer.repository.chat.chatroom.ChatRoomRepository;
import NPJ.Crewer.repository.comments.groupfeedcomment.GroupFeedCommentRepository;
import NPJ.Crewer.repository.feeds.groupfeed.GroupFeedRepository;
import NPJ.Crewer.repository.likes.likegroupfeed.LikeGroupFeedRepository;
import NPJ.Crewer.repository.member.MemberRepository;
import NPJ.Crewer.service.notification.NotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GroupFeedServiceCancelTest {

    @Mock
    private GroupFeedRepository groupFeedRepository;
    @Mock
    private LikeGroupFeedRepository likeGroupFeedRepository;
    @Mock
    private GroupFeedCommentRepository groupFeedCommentRepository;
    @Mock
    private ChatRoomRepository chatRoomRepository;
    @Mock
    private ChatParticipantRepository chatParticipantRepository;
    @Mock
    private ChatMessageRepository chatMessageRepository;
    @Mock
    private MemberRepository memberRepository;
    @Mock
    private NotificationService notificationService;

    @InjectMocks
    private GroupFeedService groupFeedService;

    private Member author;
    private Member stranger;
    private ChatRoom chatRoom;
    private GroupFeed groupFeed;

    @BeforeEach
    void setUp() {
        author = mock(Member.class);
        stranger = mock(Member.class);
        chatRoom = mock(ChatRoom.class);
        groupFeed = GroupFeed.builder()
                .id(1L)
                .title("한강 러닝 모임")
                .content("같이 뛰어요")
                .author(author)
                .status(GroupFeedStatus.ACTIVE)
                .chatRoom(chatRoom)
                .build();
    }

    @Test
    void 작성자는_모집중인_모임을_취소할_수_있다() {
        when(author.getUsername()).thenReturn("host");
        when(memberRepository.findById(1L)).thenReturn(Optional.of(author));
        when(groupFeedRepository.findById(1L)).thenReturn(Optional.of(groupFeed));
        when(chatRoom.getId()).thenReturn(UUID.randomUUID());

        groupFeedService.cancelGroupFeed(1L, 1L);

        assertThat(groupFeed.getStatus()).isEqualTo(GroupFeedStatus.CANCELLED);
        verify(notificationService).createGroupCancelledNotifications(eq(1L), anyString(), anyString());
    }

    @Test
    void 작성자가_아니면_모임을_취소할_수_없다() {
        when(author.getUsername()).thenReturn("host");
        when(stranger.getUsername()).thenReturn("guest");
        when(memberRepository.findById(2L)).thenReturn(Optional.of(stranger));
        when(groupFeedRepository.findById(1L)).thenReturn(Optional.of(groupFeed));

        assertThatThrownBy(() -> groupFeedService.cancelGroupFeed(1L, 2L))
                .isInstanceOf(AccessDeniedException.class);

        assertThat(groupFeed.getStatus()).isEqualTo(GroupFeedStatus.ACTIVE);
        verifyNoInteractions(notificationService);
    }

    @Test
    void 이미_취소되거나_완료된_모임은_다시_취소할_수_없다() {
        GroupFeed completed = GroupFeed.builder()
                .id(2L)
                .title("완료된 모임")
                .content("내용")
                .author(author)
                .status(GroupFeedStatus.COMPLETED)
                .chatRoom(chatRoom)
                .build();
        when(author.getUsername()).thenReturn("host");
        when(memberRepository.findById(1L)).thenReturn(Optional.of(author));
        when(groupFeedRepository.findById(2L)).thenReturn(Optional.of(completed));

        assertThatThrownBy(() -> groupFeedService.cancelGroupFeed(2L, 1L))
                .isInstanceOf(IllegalStateException.class);

        verifyNoInteractions(notificationService);
    }
}
