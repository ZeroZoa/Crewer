package NPJ.Crewer.comments.feedcomment.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Instant;

@Getter
@AllArgsConstructor
public class FeedCommentResponseDTO {
    private Long id;
    private String content;
    private String authorNickname;
    private String authorUsername;
    private Instant createdAt;
}