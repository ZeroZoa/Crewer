package NPJ.Crewer.running;

import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import NPJ.Crewer.running.dto.RankingResponseDTO;
import NPJ.Crewer.running.dto.RunningRecordCreateDTO;
import NPJ.Crewer.running.dto.RunningRecordResponseDTO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RunningService {

    private final RunningRepository runningRepository;
    private final MemberRepository memberRepository;
    private final RunningRecordMapper runningRecordMapper;

    // 러너의 기록 저장
    public RunningRecordResponseDTO createRunningRecord(RunningRecordCreateDTO runningRecordCreateDTO, Long memberId) {
        // 1) 회원 검증
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // 2) DTO → Entity 변환 (runner 주입 포함)
        RunningRecord record = runningRecordMapper.toEntity(runningRecordCreateDTO, member);

        // 3) 저장
        RunningRecord saved = runningRepository.save(record);

        // 4) Entity → Response DTO 변환
        return runningRecordMapper.toDTO(saved);
    }

    //해당 러너의 기록을 최신순으로 조회
    @Transactional(readOnly = true)
    public List<RunningRecordResponseDTO> getRunningRecordsByRunnerDesc(Long memberId) {
        // 1) 회원 검증
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // 2) DB 조회
        List<RunningRecord> runningRecords =
                runningRepository.findAllByRunnerIdOrderByCreatedAtDesc(member.getId());

        // 3) Entity 리스트 → DTO 리스트 변환
        return runningRecords.stream()
                .map(runningRecordMapper::toDTO)
                .toList();
    }

    //러너의 기록 삭제 (본인만 가능)
    public void deleteRunningRecord(Long runningRecordId, Long memberId) {
        // 1) 회원 검증
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // 2) 기록 조회
        RunningRecord runningRecord = runningRepository.findById(runningRecordId)
                .orElseThrow(() -> new IllegalArgumentException("달린 기록을 찾을 수 없습니다."));

        // 3) 권한 체크
        if (!runningRecord.getRunner().getUsername().equals(member.getUsername())) {
            throw new AccessDeniedException("본인의 기록만 삭제할 수 있습니다.");
        }

        // 4) 삭제
        runningRepository.delete(runningRecord);
    }

    @Transactional(readOnly = true)
    public List<RankingResponseDTO> getRankings(){
        return runningRepository.findRankings();
    }

}