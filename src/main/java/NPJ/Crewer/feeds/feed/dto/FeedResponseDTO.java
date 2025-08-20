package NPJ.Crewer.feeds.feed.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Instant;

@Getter
@AllArgsConstructor
public class FeedResponseDTO {
    private Long id;
    private String title;
    private String content;
    private String authorNickname;
    private String authorUsername;
    private Instant createdAt;
    private int likesCount;
    private int commentsCount;
}