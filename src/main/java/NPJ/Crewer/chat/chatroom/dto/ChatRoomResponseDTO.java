package NPJ.Crewer.chat.chatroom.dto;

import NPJ.Crewer.chat.chatmessage.ChatMessage;
import lombok.AllArgsConstructor;
import lombok.Builder;
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
    private Instant lastSendAt;
    private String lastContent;
    private ChatMessage.MessageType lastType;
}