package NPJ.Crewer.dto.comments.groupfeedcomment;

import NPJ.Crewer.domain.comments.groupfeedcomment.GroupFeedComment;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Instant;

@Getter
@AllArgsConstructor
public class GroupFeedCommentResponseDTO {
    private Long id;
    private String content;
    private String authorNickname;
    private String authorUsername;
    private Instant createdAt;

    public GroupFeedCommentResponseDTO(GroupFeedComment groupFeedComment) {
        this.id = groupFeedComment.getId();
        this.content = groupFeedComment.getContent();
        this.authorNickname = groupFeedComment.getAuthor().getNickname();
        this.authorUsername = groupFeedComment.getAuthor().getUsername();
        this.createdAt = groupFeedComment.getCreatedAt();
    }
}
