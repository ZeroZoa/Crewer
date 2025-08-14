package NPJ.Crewer.running.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class RankingResponseDTO {
    private Long recordId;
    private String runnerNickname;
    private double totalDistance;
    private int totalSeconds;
    private LocalDateTime createdAt;

    private String distanceCategory; // 예: "3-5km"
    private int ranking;
}
