package NPJ.Crewer.chat.directchatroom.dto;

import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
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
public class DirectChatRoomResponseDTO extends ChatRoomResponseDTO {
    private Long memberId1;
    private Long memberId2;

    public DirectChatRoomResponseDTO(UUID id, String name, int maxParticipants, int currentParticipants, Instant lastSendAt, String lastContent) {
        super(id, name, maxParticipants, currentParticipants, lastSendAt, lastContent);
    }

}
