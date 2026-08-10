package NPJ.Crewer.likes.likegroupfeed.dto;

import NPJ.Crewer.likes.likegroupfeed.LikeGroupFeed;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Instant;

@Getter
@AllArgsConstructor
public class LikeGroupFeedResponseDTO {
    private Long id;
    private String authorUsername;
    private Instant createdAt;

    public LikeGroupFeedResponseDTO(LikeGroupFeed likeGroupFeed){
        this.id = likeGroupFeed.getId();
        this.authorUsername = likeGroupFeed.getLiker().getUsername();
        this.createdAt = likeGroupFeed.getCreatedAt();
    }
}
