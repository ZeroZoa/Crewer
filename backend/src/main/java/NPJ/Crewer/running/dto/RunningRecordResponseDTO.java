package NPJ.Crewer.running.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Instant;
import java.util.List;

@Getter
@AllArgsConstructor
public class RunningRecordResponseDTO {
    private Long id;
    private String runnerNickname;
    private double totalDistance;
    private int totalSeconds;
    private Instant createdAt;
    private List<LocationPointDTO> path;
}
