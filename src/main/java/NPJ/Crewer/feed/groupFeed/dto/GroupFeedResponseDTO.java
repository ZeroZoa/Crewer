package NPJ.Crewer.feed.groupFeed.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@AllArgsConstructor
public class GroupFeedResponseDTO {
    private Long id;
    private String title;
    private String content;
    private String authorNickname;
    private UUID chatRoomId;
    private LocalDateTime createdAt;
    private int likesCount;
    private int commentsCount;
}
