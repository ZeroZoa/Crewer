package NPJ.Crewer.evaluation;

import NPJ.Crewer.chat.chatparticipant.ChatParticipant;
import NPJ.Crewer.chat.chatparticipant.ChatParticipantRepository;
import NPJ.Crewer.evaluation.dto.EvaluationResponseDTO;
import NPJ.Crewer.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.feeds.groupfeed.GroupFeedRepository;
import NPJ.Crewer.global.util.MemberUtil;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import NPJ.Crewer.profile.Profile;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class EvaluationService {
    
    private final EvaluationRepository evaluationRepository;
    private final MemberRepository memberRepository;
    private final GroupFeedRepository groupFeedRepository;
    private final ChatParticipantRepository chatParticipantRepository;
    
    @Transactional
    public void submitEvaluations(Long groupFeedId, Long evaluatorId, Map<Long, EvaluationType> evaluations) {
        if (evaluations.isEmpty()) {
            throw new EvaluationException("평가할 대상이 없습니다.");
        }
        
        Member evaluator = MemberUtil.getMemberOrThrow(memberRepository, evaluatorId);
        
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
            .orElseThrow(() -> new EvaluationException("그룹 피드를 찾을 수 없습니다."));
        
        List<Evaluation> existingEvaluations = evaluationRepository.findByGroupFeedAndEvaluator(groupFeed, evaluator);
        if (!existingEvaluations.isEmpty()) {
            throw new EvaluationException("이미 평가를 완료했습니다.");
        }
        
        List<ChatParticipant> participants = chatParticipantRepository
            .findByChatRoomId(groupFeed.getChatRoom().getId());
        List<Long> participantIds = participants.stream()
            .map(p -> p.getMember().getId())
            .toList();
        
        for (Map.Entry<Long, EvaluationType> entry : evaluations.entrySet()) {
            Long evaluatedId = entry.getKey();
            EvaluationType evaluationType = entry.getValue();
            
            if (evaluator.getId().equals(evaluatedId)) {
                throw new EvaluationException("자기 자신을 평가할 수 없습니다.");
            }
            
            if (!participantIds.contains(evaluatedId)) {
                throw new EvaluationException("그룹 참여자만 평가할 수 있습니다.");
            }
            
            Member evaluated = MemberUtil.getMemberOrThrow(memberRepository, evaluatedId);
            
            Evaluation evaluation = Evaluation.builder()
                .evaluator(evaluator)
                .evaluated(evaluated)
                .groupFeed(groupFeed)
                .type(evaluationType)
                .build();
            
            evaluationRepository.save(evaluation);
            
            Profile profile = evaluated.getProfile();
            if (profile != null) {
                profile.updateTemperature(evaluationType.getTemperatureChange());
            }
        }
    }
    
    public List<EvaluationResponseDTO> getEvaluationsByMember(Long memberId) {
        Member member = MemberUtil.getMemberOrThrow(memberRepository, memberId);
        List<Evaluation> evaluations = evaluationRepository.findByEvaluated(member);
        
        return evaluations.stream()
                .map(EvaluationResponseDTO::from)
                .collect(Collectors.toList());
    }
}
