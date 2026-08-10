package NPJ.Crewer.chat.chatmessage.dto;

import NPJ.Crewer.chat.chatmessage.ChatMessage;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.Instant;
import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class ChatMessageDTO {
    private Long id;               // ChatMessage 엔티티의 id (Long 타입)
    private UUID chatRoomId;       // 채팅방 식별자 (UUID)
    private Long senderId;         // 보낸 사람의 식별자
    private String senderNickname; // 보낸 사람의 닉네임
    private String content;        // 메시지 내용
    private ChatMessage.MessageType type;            // 메시지 타입
    private Instant timestamp; // 메시지 전송 시각
    private String senderAvatarUrl; // 프로필사진
}