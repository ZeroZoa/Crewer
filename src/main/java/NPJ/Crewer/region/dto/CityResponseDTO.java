package NPJ.Crewer.region.dto;

import NPJ.Crewer.region.City;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CityResponseDTO {
    private String regionId;
    private String regionName;
    private String fullName;
    private String level;
    private CoordinatesDTO coordinates;

    public static CityResponseDTO from(City city) {
        return CityResponseDTO.builder()
                .regionId(city.getRegionId())
                .regionName(city.getRegionName())
                .fullName(city.getFullName())
                .level(city.getLevel())
                .coordinates(CoordinatesDTO.builder()
                        .lat(city.getLatitude().doubleValue())
                        .lng(city.getLongitude().doubleValue())
                        .build())
                .build();
    }
}
