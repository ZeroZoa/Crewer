package NPJ.Crewer.dto.region;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ActivityRegionRequestDTO {
    @NotBlank(message = "활동 지역(행정동)을 선택해주세요.")
    private String regionId; // 선택된 행정동 ID
}
