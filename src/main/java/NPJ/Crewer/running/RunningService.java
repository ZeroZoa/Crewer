package NPJ.Crewer.running;

import NPJ.Crewer.member.Member;
import NPJ.Crewer.running.dto.RunningRecordCreateDTO;
import NPJ.Crewer.running.dto.RunningRecordResponseDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RunningService {

    private final RunningRepository runningRepository;

    //러너의 기록 저장
    public RunningRecordResponseDTO createRunningRecord(RunningRecordCreateDTO runningRecordCreateDTO, Member member) {
        if (member == null) throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");


        RunningRecord record = RunningRecord.builder()
                .totalDistance(runningRecordCreateDTO.getTotalDistance())
                .totalSeconds(runningRecordCreateDTO.getTotalSeconds())
                .runner(member)
                .build();

        RunningRecord saved = runningRepository.save(record);

        return new RunningRecordResponseDTO(
                saved.getId(),
                saved.getRunner().getNickname(),
                saved.getTotalDistance(),
                saved.getTotalSeconds(),
                saved.getCreatedAt()
        );
    }

    //최신순으로 러너의 기록 조회
    @Transactional(readOnly = true)
    public List<RunningRecordResponseDTO> getRunningRecordsByRunnerDesc(Member member) {
        if (member == null) {
            throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");
        }

        List<RunningRecord> runningRecords = runningRepository.findAllByRunnerIdOrderByCreatedAtDesc(member.getId());

        return runningRecords.stream()
                .map(runningRecord -> new RunningRecordResponseDTO(
                        runningRecord.getId(),
                        runningRecord.getRunner().getNickname(),
                        runningRecord.getTotalDistance(),
                        runningRecord.getTotalSeconds(),
                        runningRecord.getCreatedAt()
                ))
                .toList();
    }

    public void deleteRunningRecord(Long runningRecordId, Member member){
        //기록 불러오기
        RunningRecord runningRecord = runningRepository.findById(runningRecordId)
                .orElseThrow(() -> new IllegalArgumentException("달린 기록을 찾을 수 없습니다."));

        //피드를 삭제 권한 확인 (작성자만 가능)
        if (!runningRecord.getRunner().getUsername().equals(member.getUsername())) {
            throw new AccessDeniedException("본인의 기록만 삭제할 수 있습니다.");
        }

        //기록 삭제
        runningRepository.delete(runningRecord);
    }

}