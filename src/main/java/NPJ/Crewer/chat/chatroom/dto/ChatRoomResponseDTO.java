package NPJ.Crewer.chat.chatroom.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class ChatRoomResponseDTO {
    private UUID id;
    private String name;
    private int maxParticipants;
    private int currentParticipants;
}