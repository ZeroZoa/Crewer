package NPJ.Crewer.running;

import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.running.dto.RunningRecordCreateDTO;
import NPJ.Crewer.running.dto.RunningRecordResponseDTO;
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
            @AuthenticationPrincipal Member member) {

        if (member == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        RunningRecordResponseDTO response = runningService.createRunningRecord(runningRecordCreateDTO, member);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<RunningRecordResponseDTO>> getMyRunningRecords(@AuthenticationPrincipal Member member) {
        List<RunningRecordResponseDTO> records = runningService.getRunningRecordsByRunnerDesc(member);
        return ResponseEntity.ok(records);
    }
}