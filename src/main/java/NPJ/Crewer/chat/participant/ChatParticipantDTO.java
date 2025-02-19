package NPJ.Crewer.chat.participant;

import lombok.*;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatParticipantDTO {
    private Long memberId;  // 참가한 유저 ID
    private String nickname; // 참가한 유저 닉네임
}