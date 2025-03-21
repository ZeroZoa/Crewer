package NPJ.Crewer.chat.chatmessage.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Builder
public class ChatMessageDTO {
    private Long id;               // ChatMessage 엔티티의 id (Long 타입)
    private UUID chatRoomId;       // 채팅방 식별자 (UUID)
    private Long senderId;         // 보낸 사람의 식별자
    private String senderNickname; // 보낸 사람의 닉네임
    private String content;        // 메시지 내용
    private LocalDateTime timestamp; // 메시지 전송 시각
}