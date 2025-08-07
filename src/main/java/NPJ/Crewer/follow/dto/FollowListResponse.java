package NPJ.Crewer.follow.dto;

import NPJ.Crewer.profile.ProfileDTO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FollowListResponse {
    private List<ProfileDTO> members;
    private int totalCount;
    private boolean hasNext;
} 