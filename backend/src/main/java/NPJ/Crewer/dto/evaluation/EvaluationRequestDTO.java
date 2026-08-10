package NPJ.Crewer.dto.evaluation;

import NPJ.Crewer.domain.evaluation.EvaluationType;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class EvaluationRequestDTO {
    @NotNull(message = "그룹 피드 ID가 필요합니다.")
    private Long groupFeedId;

    @NotEmpty(message = "평가할 대상이 없습니다.")
    private Map<Long, EvaluationType> evaluations;
}

