package NPJ.Crewer.region.dto;

import NPJ.Crewer.region.District;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DistrictResponseDTO {
    private String regionId;
    private String regionName;
    private String fullName;
    private String level;
    private ParentRegionDTO parentRegion;
    private CoordinatesDTO coordinates;
    private String geojsonData; // GeoJSON 경계 데이터 추가

    public static DistrictResponseDTO from(District district) {
        return DistrictResponseDTO.builder()
                .regionId(district.getRegionId())
                .regionName(district.getRegionName())
                .fullName(district.getFullName())
                .level(district.getLevel())
                .parentRegion(ParentRegionDTO.builder()
                        .regionId(district.getCity().getRegionId())
                        .regionName(district.getCity().getRegionName())
                        .fullName(district.getCity().getFullName())
                        .build())
                .coordinates(CoordinatesDTO.builder()
                        .lat(district.getLatitude().doubleValue())
                        .lng(district.getLongitude().doubleValue())
                        .build())
                .geojsonData(district.getGeojsonData()) // GeoJSON 데이터 추가
                .build();
    }
}
