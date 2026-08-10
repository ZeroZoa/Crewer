package NPJ.Crewer.dto.feeds.groupfeed;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GroupFeedCompleteResponseDTO {
    private Long id;
    private String title;
    private String status;
    private String message;
}
