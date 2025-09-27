package NPJ.Crewer.evaluation;

import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/evaluation")
@RequiredArgsConstructor
public class EvaluationController {
    
    private final EvaluationService evaluationService;
    
    @GetMapping("/group-feed/{groupFeedId}/members")
    public ResponseEntity<List<Member>> getGroupFeedMembers(@PathVariable Long groupFeedId) {
        List<Member> members = evaluationService.getGroupFeedMembers(groupFeedId);
        return ResponseEntity.ok(members);
    }
    
    @PostMapping
    public ResponseEntity<Void> submitEvaluations(
            @RequestBody EvaluationRequest request,
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
    public ResponseEntity<List<Evaluation>> getMyEvaluations(Authentication authentication) {
        Member member = (Member) authentication.getPrincipal();
        List<Evaluation> evaluations = evaluationService.getEvaluationsByMember(member.getId());
        return ResponseEntity.ok(evaluations);
    }
    
    // DTO 클래스
    public static class EvaluationRequest {
        private Long groupFeedId;
        private Map<Long, EvaluationType> evaluations;
        
        // Getters and Setters
        public Long getGroupFeedId() { return groupFeedId; }
        public void setGroupFeedId(Long groupFeedId) { this.groupFeedId = groupFeedId; }
        public Map<Long, EvaluationType> getEvaluations() { return evaluations; }
        public void setEvaluations(Map<Long, EvaluationType> evaluations) { this.evaluations = evaluations; }
    }
}
