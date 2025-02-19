package NPJ.Crewer.chat.room;

import NPJ.Crewer.chat.participant.ChatParticipantDTO;
import lombok.*;

import java.time.LocalDateTime;
import java.util.Set;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatRoomDTO {
    private Long id; // UUID → Long 변경
    private String name;
    private ChatRoomType type;
    private Long ownerId;
    private Set<ChatParticipantDTO> participants;
    private LocalDateTime createdAt;
    private LocalDateTime lastMessageAt;
}