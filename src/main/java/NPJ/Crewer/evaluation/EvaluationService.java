package NPJ.Crewer.evaluation;

import NPJ.Crewer.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.feeds.groupfeed.GroupFeedRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import NPJ.Crewer.notification.NotificationService;
import NPJ.Crewer.profile.Profile;
import NPJ.Crewer.profile.ProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class EvaluationService {
    
    private final EvaluationRepository evaluationRepository;
    private final MemberRepository memberRepository;
    private final GroupFeedRepository groupFeedRepository;
    private final ProfileRepository profileRepository;
    private final NotificationService notificationService;
    
    public List<Member> getGroupFeedMembers(Long groupFeedId) {
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
            .orElseThrow(() -> new IllegalArgumentException("GroupFeed not found"));
        
        // 실제 구현에서는 ChatRoom의 참여자 목록을 가져와야 함
        // 여기서는 간단히 그룹 피드 작성자만 반환
        return List.of(groupFeed.getAuthor());
    }
    
    @Transactional
    public void submitEvaluations(Long groupFeedId, Long evaluatorId, Map<Long, EvaluationType> evaluations) {
        Member evaluator = memberRepository.findById(evaluatorId)
            .orElseThrow(() -> new IllegalArgumentException("Evaluator not found"));
        
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
            .orElseThrow(() -> new IllegalArgumentException("GroupFeed not found"));
        
        // 이미 평가했는지 확인
        List<Evaluation> existingEvaluations = evaluationRepository.findByGroupFeedAndEvaluator(groupFeed, evaluator);
        if (!existingEvaluations.isEmpty()) {
            throw new IllegalArgumentException("Already evaluated this group feed");
        }
        
        // 평가 저장 및 온도 업데이트
        for (Map.Entry<Long, EvaluationType> entry : evaluations.entrySet()) {
            Long evaluatedId = entry.getKey();
            EvaluationType evaluationType = entry.getValue();
            
            Member evaluated = memberRepository.findById(evaluatedId)
                .orElseThrow(() -> new IllegalArgumentException("Evaluated member not found"));
            
            // 평가 저장
            Evaluation evaluation = Evaluation.builder()
                .evaluator(evaluator)
                .evaluated(evaluated)
                .groupFeed(groupFeed)
                .type(evaluationType)
                .build();
            
            evaluationRepository.save(evaluation);
            
            // 온도 업데이트
            Profile profile = profileRepository.findById(evaluatedId)
                .orElseThrow(() -> new IllegalArgumentException("Profile not found"));
            
            profile.updateTemperature(evaluationType.getTemperatureChange());
            profileRepository.save(profile);
            
            // 익명성 보장을 위해 평가 받음 알림 생성하지 않음
        }
    }
    
    public List<Evaluation> getEvaluationsByMember(Long memberId) {
        Member member = memberRepository.findById(memberId)
            .orElseThrow(() -> new IllegalArgumentException("Member not found"));
        return evaluationRepository.findByEvaluated(member);
    }
}
