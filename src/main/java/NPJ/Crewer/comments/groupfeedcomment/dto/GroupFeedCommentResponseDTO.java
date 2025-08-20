package NPJ.Crewer.comments.groupfeedcomment.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Instant;

@Getter
@AllArgsConstructor
public class GroupFeedCommentResponseDTO {
    private Long id;
    private String content;
    private String authorNickname;
    private Instant createdAt;
}
