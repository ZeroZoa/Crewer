package NPJ.Crewer.chat.directchatroom.dto;

import NPJ.Crewer.chat.chatmessage.ChatMessage;
import NPJ.Crewer.chat.chatroom.ChatRoom;
import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
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
