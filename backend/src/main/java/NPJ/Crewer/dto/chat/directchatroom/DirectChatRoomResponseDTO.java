package NPJ.Crewer.dto.chat.directchatroom;

import NPJ.Crewer.domain.chat.chatmessage.ChatMessage;
import NPJ.Crewer.domain.chat.chatroom.ChatRoom;
import NPJ.Crewer.dto.chat.chatroom.ChatRoomResponseDTO;
import lombok.*;
import lombok.experimental.SuperBuilder;

import java.time.Instant;
import java.util.UUID;
@Data
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class DirectChatRoomResponseDTO extends ChatRoomResponseDTO {
    private String nickname;
    private String avatarUrl;
    public DirectChatRoomResponseDTO(UUID id, String name, int maxParticipants, int currentParticipants, ChatRoom.ChatRoomType type, Instant lastSendAt, String lastContent, ChatMessage.MessageType lastType) {
        super(id, name, maxParticipants, currentParticipants, type, lastSendAt, lastContent, lastType);
    }

}
