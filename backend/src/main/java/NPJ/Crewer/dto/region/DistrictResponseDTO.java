package NPJ.Crewer.dto.region;

import NPJ.Crewer.domain.region.District;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder(toBuilder = true)
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

    // 상세 조회용 (geojsonData 포함 - 지도 폴리곤 렌더링에 필요)
    public static DistrictResponseDTO from(District district) {
        return fromSummary(district).toBuilder()
                .geojsonData(district.getGeojsonData())
                .build();
    }

    // 목록/검색/자동완성용 (geojsonData 제외 - 응답 크기 절감)
    public static DistrictResponseDTO fromSummary(District district) {
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
                .build();
    }
}
