package NPJ.Crewer.controller.running;

import NPJ.Crewer.service.running.RunningService;

import NPJ.Crewer.dto.chat.chatroom.ChatRoomResponseDTO;
import NPJ.Crewer.domain.member.Member;
import NPJ.Crewer.dto.running.RankingResponseDTO;
import NPJ.Crewer.dto.running.RunningRecordCreateDTO;
import NPJ.Crewer.dto.running.RunningRecordResponseDTO;
import NPJ.Crewer.dto.running.response.RankingApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/running")
public class RunningController {

    private final RunningService runningService;

    // 달리기 기록 생성
    @PostMapping("/create")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<RunningRecordResponseDTO> createRunningRecord(
            @Valid @RequestBody RunningRecordCreateDTO runningRecordCreateDTO,
            @AuthenticationPrincipal(expression = "id") Long memberId) {

        RunningRecordResponseDTO response = runningService.createRunningRecord(runningRecordCreateDTO, memberId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<RunningRecordResponseDTO>> getMyRunningRecords(@AuthenticationPrincipal(expression = "id") Long memberId) {
        List<RunningRecordResponseDTO> records = runningService.getRunningRecordsByRunnerDesc(memberId);
        return ResponseEntity.ok(records);
    }

    @GetMapping("/ranking")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<RankingApiResponse> getRankings(@AuthenticationPrincipal(expression = "id") Long memberId){
        RankingApiResponse rankings = runningService.getRankings(memberId);
        return ResponseEntity.ok(rankings);
    }

    @DeleteMapping("/{runningRecordId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> deleteRunningRecord(@PathVariable("runningRecordId") Long runningRecordId,
                                                     @AuthenticationPrincipal(expression = "id") Long memberId) {
        runningService.deleteRunningRecord(runningRecordId, memberId);
        return ResponseEntity.noContent().build();
    }
}