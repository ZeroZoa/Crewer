package NPJ.Crewer.running.dto;


import lombok.Getter;
import lombok.Setter;


import java.time.LocalDateTime;
import java.util.List;


@Getter
@Setter
public class RunningRecordCreateDTO {
    private String runnerNickname;
    private LocalDateTime createdAt;
    private int totalSeconds;
    private double totalDistance;
    private List<LocationPointDTO> path;
}