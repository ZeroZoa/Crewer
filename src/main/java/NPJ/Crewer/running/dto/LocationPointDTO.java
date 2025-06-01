package NPJ.Crewer.running.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LocationPointDTO {
    private double latitude;  // 위도
    private double longitude; // 경도
}
