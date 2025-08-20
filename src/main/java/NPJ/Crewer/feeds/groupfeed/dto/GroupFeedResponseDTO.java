package NPJ.Crewer.feeds.groupfeed.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Instant;
import java.util.UUID;

@Getter
@AllArgsConstructor
public class GroupFeedResponseDTO {
    private Long id;
    private String title;
    private String content;
    private String authorNickname;
    private String authorUsername;
    private String meetingPlace;
    private Instant deadline;
    private UUID chatRoomId;
    private Instant createdAt;
    private int likesCount;
    private int commentsCount;
}
