package NPJ.Crewer.chat.participant;

import NPJ.Crewer.chat.room.ChatRoom;
import NPJ.Crewer.member.Member;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatParticipant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "chat_room_id", nullable = false)
    private ChatRoom chatRoom;  // N:1 관계 (하나의 채팅방에 여러 참가자 가능)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;  // N:1 관계 (하나의 유저가 여러 채팅방에 참가 가능)
}