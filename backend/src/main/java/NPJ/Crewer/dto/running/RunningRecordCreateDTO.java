package NPJ.Crewer.dto.running;

import jakarta.validation.constraints.Positive;
import lombok.Builder;
import lombok.Getter;

import java.time.Instant;
import java.util.List;

@Getter
@Builder
public class RunningRecordCreateDTO {
    private String runnerNickname;
    private Instant createdAt;

    @Positive(message = "달린 시간은 0보다 커야 합니다.")
    private int totalSeconds;

    @Positive(message = "달린 거리는 0보다 커야 합니다.")
    private double totalDistance;

    private List<LocationPointDTO> path;
}