package NPJ.Crewer.comments.feedcomment.dto;

import NPJ.Crewer.comments.feedcomment.FeedComment;
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


    public FeedCommentResponseDTO(FeedComment feedComment) {
        this.id = feedComment.getId();
        this.content = feedComment.getContent();
        this.authorNickname = feedComment.getAuthor().getNickname();
        this.authorUsername = feedComment.getAuthor().getUsername();
        this.createdAt = feedComment.getCreatedAt();
    }
}