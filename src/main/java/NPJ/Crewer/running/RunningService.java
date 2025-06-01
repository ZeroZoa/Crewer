package NPJ.Crewer.running;

import NPJ.Crewer.member.Member;
import NPJ.Crewer.running.dto.RunningRecordCreateDTO;
import NPJ.Crewer.running.dto.RunningRecordResponseDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RunningService {

    private final RunningRepository runningRepository;

    //러너의 기록 저장
    public RunningRecordResponseDTO createRunningRecord(RunningRecordCreateDTO dto, Member member) {
        if (member == null) throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");

        RunningRecord record = RunningRecord.builder()
                .totalDistance(dto.getTotalDistance())
                .totalSeconds(dto.getTotalSeconds())
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
    public List<RunningRecordResponseDTO> getRecordsByRunnerDesc(Member member) {
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

}