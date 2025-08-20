package NPJ.Crewer.running;

import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import NPJ.Crewer.running.dto.RankingResponseDTO;
import NPJ.Crewer.running.dto.RunningRecordCreateDTO;
import NPJ.Crewer.running.dto.RunningRecordResponseDTO;
import NPJ.Crewer.running.dto.response.MyRankingInfo;
import NPJ.Crewer.running.dto.response.RankingApiResponse;
import NPJ.Crewer.running.dto.response.RankingInfo;
import NPJ.Crewer.running.dto.response.RankingResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

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
    public RankingApiResponse getRankings(Long memberId){
        // 1. DB에서는 인터페이스 기반으로 데이터를 효율적으로 가져옵니다.
        List<RankingResponse> allRankings = runningRepository.findRankings();

        // 2. 카테고리별로 그룹핑합니다.
        Map<String, List<RankingResponse>> rankingsByCategory = allRankings.stream()
                .collect(Collectors.groupingBy(RankingResponse::getDistanceCategory));

        List<MyRankingInfo> myRankingsResult = new ArrayList<>();
        Map<String, List<RankingInfo>> topRankingsResult = new HashMap<>();

        // 3. 그룹핑된 데이터를 순회하며 DTO 클래스로 변환 및 가공합니다.
        for (Map.Entry<String, List<RankingResponse>> entry : rankingsByCategory.entrySet()) {
            String category = entry.getKey();
            List<RankingResponse> categoryRanks = entry.getValue();
            int totalRankedCount = categoryRanks.size();

            // '내 랭킹' 찾기 및 DTO 변환
            categoryRanks.stream()
                    .filter(rank -> rank.getRunnerId().equals(memberId))
                    .findFirst()
                    .ifPresent(myRecord -> {
                        // 인터페이스(myRecord)를 DTO 클래스(RankingInfo)로 변환
                        RankingInfo myRecordDto = RankingInfo.from(myRecord);
                        myRankingsResult.add(
                                new MyRankingInfo(category, myRecordDto.getRanking(), totalRankedCount, myRecordDto)
                        );
                    });

            // '상위 N명' 랭킹 추출 및 DTO 변환
            List<RankingInfo> topN = categoryRanks.stream()
                    .limit(10)
                    // 스트림의 각 인터페이스를 DTO 클래스로 변환
                    .map(RankingInfo::from)
                    .collect(Collectors.toList());
            topRankingsResult.put(category, topN);
        }

        return new RankingApiResponse(myRankingsResult, topRankingsResult);
    }

}