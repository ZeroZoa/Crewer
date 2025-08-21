package NPJ.Crewer.chat.chatmessage.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Getter
@Setter
public class ChatMessagePayloadDTO {
    private String type;
    private String content;
    private Instant timeStamp;
}