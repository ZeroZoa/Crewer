package NPJ.Crewer.dto.likes.likefeed;

import NPJ.Crewer.domain.likes.likefeed.LikeFeed;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Instant;

@Getter
@AllArgsConstructor
public class LikeFeedResponseDTO {
    private Long id;
    private String authorUsername;
    private Instant createdAt;

    public LikeFeedResponseDTO(LikeFeed likeFeed){
        this.id = likeFeed.getId();
        this.authorUsername = likeFeed.getLiker().getUsername();
        this.createdAt = likeFeed.getCreatedAt();
    }
}
