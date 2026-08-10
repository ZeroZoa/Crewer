package NPJ.Crewer.chat.chatroom.dto;

import NPJ.Crewer.chat.chatmessage.ChatMessage;
import NPJ.Crewer.chat.chatroom.ChatRoom;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import java.time.Instant;
import java.util.UUID;

@Getter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class ChatRoomResponseDTO {
    private UUID id;
    private String name;
    private int maxParticipants;
    private int currentParticipants;
    private ChatRoom.ChatRoomType type;
    private Instant lastSendAt;
    private String lastContent;
    private ChatMessage.MessageType lastType;
}