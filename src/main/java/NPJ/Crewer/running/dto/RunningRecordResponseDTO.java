package NPJ.Crewer.running.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@AllArgsConstructor
public class RunningRecordResponseDTO {
    private Long id;
    private String runnerNickname;
    private double totalDistance;
    private int totalSeconds;
    private LocalDateTime createdAt;
}
