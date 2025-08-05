package NPJ.Crewer.running.dto;

import lombok.Builder;
import lombok.Getter;
import java.time.LocalDateTime;
import java.util.List;



@Getter
@Builder
public class RunningRecordCreateDTO {
    private String runnerNickname;
    private LocalDateTime createdAt;
    private int totalSeconds;
    private double totalDistance;
    private List<LocationPointDTO> path;
}