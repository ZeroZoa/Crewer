package NPJ.Crewer.running.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class RunningRecordResponseDTO {
    private Long id;
    private String runnerNickname;
    private double totalDistance;
    private int totalSeconds;
    private double pace;
    private LocalDateTime createdAt;
}
