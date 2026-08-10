package NPJ.Crewer.follow.dto;

import NPJ.Crewer.profile.SimpleProfileDTO;
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
    private List<SimpleProfileDTO> members;
    private int totalCount;
    private boolean hasNext;
} 