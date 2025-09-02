package NPJ.Crewer.region.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParentRegionDTO {
    private String regionId;
    private String regionName;
    private String fullName;
}
