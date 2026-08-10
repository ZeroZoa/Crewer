package NPJ.Crewer.notification;

import NPJ.Crewer.chat.chatparticipant.ChatParticipant;
import NPJ.Crewer.chat.chatparticipant.ChatParticipantRepository;
import NPJ.Crewer.evaluation.EvaluationRepository;
import NPJ.Crewer.global.util.MemberUtil;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import NPJ.Crewer.notification.dto.NotificationResponseDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class NotificationService {
    
    private final NotificationRepository notificationRepository;
    private final MemberRepository memberRepository;
    private final ChatParticipantRepository chatParticipantRepository;
    private final EvaluationRepository evaluationRepository;
    
    public List<NotificationResponseDTO> getNotificationDTOsByMember(Long memberId) {
        Member member = MemberUtil.getMemberOrThrow(memberRepository, memberId);
        List<Notification> notifications = notificationRepository.findByRecipientOrderByCreatedAtDesc(member);
        
        // N+1 방지: 평가 요청 알림의 groupFeedId 목록 수집
        List<Long> groupFeedIds = notifications.stream()
                .filter(n -> n.getType() == NotificationType.EVALUATION_REQUEST && n.getRelatedGroupFeedId() != null)
                .map(Notification::getRelatedGroupFeedId)
                .distinct()
                .toList();
        
        // 한 번의 쿼리로 완료된 groupFeedId 목록 조회
        Set<Long> completedGroupFeedIds = groupFeedIds.isEmpty() 
                ? new HashSet<>() 
                : new HashSet<>(evaluationRepository.findCompletedGroupFeedIdsByEvaluator(groupFeedIds, memberId));
        
        return notifications.stream()
                .map(notification -> {
                    boolean isCompleted = notification.getType() == NotificationType.EVALUATION_REQUEST
                            && notification.getRelatedGroupFeedId() != null
                            && completedGroupFeedIds.contains(notification.getRelatedGroupFeedId());
                    
                    return NotificationResponseDTO.from(notification, isCompleted);
                })
                .collect(Collectors.toList());
    }
    
    @Transactional
    public void markAsRead(Long notificationId, Long memberId) {
        Notification notification = notificationRepository.findById(notificationId)
            .orElseThrow(() -> new NotificationException("알림을 찾을 수 없습니다."));
        
        if (!notification.getRecipient().getId().equals(memberId)) {
            throw new NotificationException("알림에 접근할 권한이 없습니다.");
        }
        
        notification.markAsRead();
        notificationRepository.save(notification);
    }
    
    @Transactional
    public void createEvaluationRequestNotifications(Long groupFeedId, String groupFeedTitle, String chatRoomId) {
        // 채팅방의 모든 참여자 조회
        List<ChatParticipant> participants = chatParticipantRepository.findByChatRoomId(java.util.UUID.fromString(chatRoomId));
        
        // 모든 참여자에게 평가 요청 알림 생성
        List<Notification> notifications = participants.stream()
                .map(ChatParticipant::getMember)
                .map(participant -> Notification.builder()
                        .recipient(participant)
                        .type(NotificationType.EVALUATION_REQUEST)
                        .title("크루원 평가 요청")
                        .content(groupFeedTitle + " 모임이 완료되었습니다. 크루원들을 평가해주세요.")
                        .relatedGroupFeedId(groupFeedId)
                        .build())
                .collect(Collectors.toList());
        
        notificationRepository.saveAll(notifications);
    }
    
    @Transactional
    public void createEvaluationReceivedNotification(Member recipient, Member evaluator, Long groupFeedId) {
        Notification notification = Notification.builder()
            .recipient(recipient)
            .type(NotificationType.EVALUATION_RECEIVED)
            .title("평가를 받았습니다")
            .content(evaluator.getNickname() + "님이 당신을 평가했습니다.")
            .relatedGroupFeedId(groupFeedId) // ID만 저장
            .build();
        
        notificationRepository.save(notification);
    }
    
    @Transactional
    public void createGroupCompletedNotification(Member recipient, Long groupFeedId) {
        Notification notification = Notification.builder()
            .recipient(recipient)
            .type(NotificationType.GROUP_COMPLETED)
            .title("모임이 완료되었습니다")
            .content("참여하신 모임이 완료되었습니다.")
            .relatedGroupFeedId(groupFeedId) // ID만 저장
            .build();
        
        notificationRepository.save(notification);
    }
    
    // 읽지 않은 알림 개수 조회
    public int getUnreadNotificationCount(Long memberId) {
        return notificationRepository.countByRecipientIdAndIsReadFalse(memberId);
    }
    
    @Transactional
    public void deleteOldNotifications() {
        Instant oneWeekAgo = Instant.now().minus(7, java.time.temporal.ChronoUnit.DAYS);
        List<Notification> oldNotifications = notificationRepository.findByCreatedAtBefore(oneWeekAgo);
        
        if (!oldNotifications.isEmpty()) {
            notificationRepository.deleteAll(oldNotifications);
        }
    }
}
