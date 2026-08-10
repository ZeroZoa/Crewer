package NPJ.Crewer.follow.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FollowStatusResponse {
    @JsonProperty("isFollowing")
    private boolean isFollowing;
    
    @JsonProperty("followerCount")
    private long followerCount;
    
    @JsonProperty("followingCount")
    private long followingCount;
} 