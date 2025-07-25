package NPJ.Crewer.comment.feedComment.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class FeedCommentResponseDTO {
    private Long id;
    private String content;
    private String authorNickname;
    private String authorUsername;
    private LocalDateTime createdAt;
}