package NPJ.Crewer.evaluation.dto;

import NPJ.Crewer.evaluation.EvaluationType;
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
    private Long groupFeedId;
    private Map<Long, EvaluationType> evaluations;
}

