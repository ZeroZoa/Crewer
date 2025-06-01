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
//    private double pace = totalDistance / 1000 / totalSeconds * 3600;
    private List<LocationPointDTO> path;
}