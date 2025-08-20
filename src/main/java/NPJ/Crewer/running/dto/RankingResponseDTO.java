package NPJ.Crewer.running.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Instant;

@Getter
@AllArgsConstructor
public class RankingResponseDTO {
    private Long recordId;
    private Long runnerId;
    private double totalDistance;
    private int totalSeconds;
    private Instant createdAt;

    private String distanceCategory;
    private int ranking;
}
