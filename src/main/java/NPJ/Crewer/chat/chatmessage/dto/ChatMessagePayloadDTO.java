package NPJ.Crewer.chat.chatmessage.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class ChatMessagePayloadDTO {
    private String content;
    private LocalDateTime timeStamp;
}