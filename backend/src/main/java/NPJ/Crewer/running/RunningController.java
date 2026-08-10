package NPJ.Crewer.running;

import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.running.dto.RankingResponseDTO;
import NPJ.Crewer.running.dto.RunningRecordCreateDTO;
import NPJ.Crewer.running.dto.RunningRecordResponseDTO;
import NPJ.Crewer.running.dto.response.RankingApiResponse;
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
}