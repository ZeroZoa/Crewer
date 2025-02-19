package NPJ.Crewer.chat.room;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatRoomCreateDTO {
    private String name;  // 채팅방 이름
    private ChatRoomType type;  // 채팅방 타입 (GROUP, PRIVATE)
}