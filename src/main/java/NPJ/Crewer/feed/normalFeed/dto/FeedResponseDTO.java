package NPJ.Crewer.feed.normalFeed.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class FeedResponseDTO {
    private Long id;
    private String title;
    private String content;
    private String authorNickname;
    private String authorUsername;
    private LocalDateTime createdAt;
    private int likesCount;
    private int commentsCount;
}