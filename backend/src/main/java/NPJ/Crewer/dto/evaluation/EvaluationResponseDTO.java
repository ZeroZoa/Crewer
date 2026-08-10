package NPJ.Crewer.dto.evaluation;

import NPJ.Crewer.domain.evaluation.Evaluation;
import NPJ.Crewer.domain.evaluation.EvaluationType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EvaluationResponseDTO {
    private Long id;
    private String evaluatorNickname;
    private String evaluatedNickname;
    private Long groupFeedId;
    private EvaluationType type;
    private Instant createdAt;

    /**
     * Evaluation 엔티티로부터 EvaluationResponseDTO를 생성한다.
     */
    public static EvaluationResponseDTO from(Evaluation evaluation) {
        return EvaluationResponseDTO.builder()
                .id(evaluation.getId())
                .evaluatorNickname(evaluation.getEvaluator().getNickname())
                .evaluatedNickname(evaluation.getEvaluated().getNickname())
                .groupFeedId(evaluation.getGroupFeed().getId())
                .type(evaluation.getType())
                .createdAt(evaluation.getCreatedAt())
                .build();
    }
}

