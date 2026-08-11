package NPJ.Crewer.dto.feeds.feed;

import NPJ.Crewer.domain.feeds.feed.Feed;
import ch.qos.logback.core.net.SMTPAppenderBase;
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
    private String authorAvatarUrl;
    private Instant createdAt;
    private int likesCount;
    private int commentsCount;

    public FeedResponseDTO(Feed feed) {
        this.id = feed.getId();
        this.title = feed.getTitle();
        this.content = feed.getContent();
        this.authorNickname = feed.getAuthor().getNickname();
        this.authorUsername = feed.getAuthor().getUsername();
        this.authorAvatarUrl = feed.getAuthor().getProfile().getAvatarUrl();
        this.createdAt = feed.getCreatedAt();
        this.likesCount = feed.getLikes().size();
        this.commentsCount = feed.getComments().size();
    }

    public FeedResponseDTO(Long id, String title, String content, String authorNickname,
                           String authorUsername, String authorAvatarUrl, Instant createdAt, Long likesCount, Long commentsCount) {
        this.id = id;
        this.title = title;
        this.content = content;
        this.authorNickname = authorNickname;
        this.authorUsername = authorUsername;
        this.authorAvatarUrl = authorAvatarUrl;
        this.createdAt = createdAt;
        // COUNT의 결과인 Long 타입을 DTO의 int 필드에 맞게 변환해줍니다.
        this.likesCount = likesCount.intValue();
        this.commentsCount = commentsCount.intValue();
    }

}