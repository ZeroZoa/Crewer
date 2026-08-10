package NPJ.Crewer.evaluation;

import NPJ.Crewer.evaluation.dto.EvaluationRequestDTO;
import NPJ.Crewer.evaluation.dto.EvaluationResponseDTO;
import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/evaluation")
@RequiredArgsConstructor
public class EvaluationController {
    
    private final EvaluationService evaluationService;
    
    @PostMapping
    public ResponseEntity<Void> submitEvaluations(
            @RequestBody EvaluationRequestDTO request,
            Authentication authentication) {
        Member member = (Member) authentication.getPrincipal();
        evaluationService.submitEvaluations(
            request.getGroupFeedId(),
            member.getId(),
            request.getEvaluations()
        );
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/my-evaluations")
    public ResponseEntity<List<EvaluationResponseDTO>> getMyEvaluations(Authentication authentication) {
        Member member = (Member) authentication.getPrincipal();
        List<EvaluationResponseDTO> evaluationDTOs = evaluationService.getEvaluationsByMember(member.getId());
        return ResponseEntity.ok(evaluationDTOs);
    }
}
