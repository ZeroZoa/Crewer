package NPJ.Crewer.controller.evaluation;

import NPJ.Crewer.service.evaluation.EvaluationService;

import NPJ.Crewer.dto.evaluation.EvaluationRequestDTO;
import NPJ.Crewer.dto.evaluation.EvaluationResponseDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/evaluation")
@RequiredArgsConstructor
public class EvaluationController {

    private final EvaluationService evaluationService;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> submitEvaluations(
            @Valid @RequestBody EvaluationRequestDTO request,
            @AuthenticationPrincipal(expression = "id") Long memberId) {
        evaluationService.submitEvaluations(
            request.getGroupFeedId(),
            memberId,
            request.getEvaluations()
        );
        return ResponseEntity.ok().build();
    }

    @GetMapping("/my-evaluations")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<EvaluationResponseDTO>> getMyEvaluations(@AuthenticationPrincipal(expression = "id") Long memberId) {
        List<EvaluationResponseDTO> evaluationDTOs = evaluationService.getEvaluationsByMember(memberId);
        return ResponseEntity.ok(evaluationDTOs);
    }
}
