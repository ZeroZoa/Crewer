package NPJ.Crewer.region.dto;

import NPJ.Crewer.region.Province;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProvinceResponseDTO {
    private String regionId;
    private String regionName;
    private String level;
    private CoordinatesDTO coordinates;

    public static ProvinceResponseDTO from(Province province) {
        return ProvinceResponseDTO.builder()
                .regionId(province.getRegionId())
                .regionName(province.getRegionName())
                .level(province.getLevel())
                .coordinates(CoordinatesDTO.builder()
                        .lat(province.getLatitude())
                        .lng(province.getLongitude())
                        .build())
                .build();
    }
}
