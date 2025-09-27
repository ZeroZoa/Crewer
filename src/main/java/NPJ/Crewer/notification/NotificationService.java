package NPJ.Crewer.notification;

import NPJ.Crewer.chat.chatparticipant.ChatParticipant;
import NPJ.Crewer.chat.chatparticipant.ChatParticipantRepository;
import NPJ.Crewer.evaluation.EvaluationRepository;
import NPJ.Crewer.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.feeds.groupfeed.GroupFeedRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import NPJ.Crewer.notification.dto.NotificationResponseDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class NotificationService {
    
    private final NotificationRepository notificationRepository;
    private final MemberRepository memberRepository;
    private final GroupFeedRepository groupFeedRepository;
    private final ChatParticipantRepository chatParticipantRepository;
    private final EvaluationRepository evaluationRepository;
    
    public List<Notification> getNotificationsByMember(Long memberId) {
        Member member = memberRepository.findById(memberId)
            .orElseThrow(() -> new IllegalArgumentException("Member not found"));
        return notificationRepository.findByRecipientOrderByCreatedAtDesc(member);
    }
    
    public List<NotificationResponseDTO> getNotificationDTOsByMember(Long memberId) {
        Member member = memberRepository.findById(memberId)
            .orElseThrow(() -> new IllegalArgumentException("Member not found"));
        List<Notification> notifications = notificationRepository.findByRecipientOrderByCreatedAtDesc(member);
        return notifications.stream()
                .map(notification -> {
                    NotificationResponseDTO dto = new NotificationResponseDTO(notification);
                    
                    // 평가 요청 알림인 경우 평가 완료 여부 확인
                    if (notification.getType() == NPJ.Crewer.notification.NotificationType.EVALUATION_REQUEST 
                        && notification.getRelatedGroupFeedId() != null) {
                        boolean isCompleted = isEvaluationCompleted(notification.getRelatedGroupFeedId(), memberId);
                        dto = NotificationResponseDTO.builder()
                                .id(dto.getId())
                                .recipientNickname(dto.getRecipientNickname())
                                .type(dto.getType())
                                .title(dto.getTitle())
                                .content(dto.getContent())
                                .isRead(dto.isRead())
                                .relatedGroupFeedId(dto.getRelatedGroupFeedId())
                                .createdAt(dto.getCreatedAt())
                                .isEvaluationCompleted(isCompleted)
                                .build();
                    }
                    
                    return dto;
                })
                .collect(Collectors.toList());
    }
    
    @Transactional
    public void markAsRead(Long notificationId, Long memberId) {
        Member member = memberRepository.findById(memberId)
            .orElseThrow(() -> new IllegalArgumentException("Member not found"));
        
        Notification notification = notificationRepository.findById(notificationId)
            .orElseThrow(() -> new IllegalArgumentException("Notification not found"));
        
        if (!notification.getRecipient().getId().equals(memberId)) {
            throw new IllegalArgumentException("Unauthorized access to notification");
        }
        
        notification.markAsRead();
        notificationRepository.save(notification);
    }
    
    @Transactional
    public void createEvaluationRequestNotifications(Long groupFeedId, String groupFeedTitle, String chatRoomId) {
        // 그룹 피드 참여자들에게 평가 요청 알림 생성
        // ChatRoom의 모든 참여자에게 알림 발송
        
        // GroupFeed 조회 (채팅방 정보 가져오기 위해)
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("GroupFeed not found with id: " + groupFeedId));
        
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
    
    // 1주일 이상 된 알림 자동 삭제 (스케줄러용)
    @Transactional
    public void deleteOldNotifications() {
        Instant oneWeekAgo = Instant.now().minus(7, java.time.temporal.ChronoUnit.DAYS);
        List<Notification> oldNotifications = notificationRepository.findByCreatedAtBefore(oneWeekAgo);
        
        if (!oldNotifications.isEmpty()) {
            notificationRepository.deleteAll(oldNotifications);
            System.out.println("Deleted " + oldNotifications.size() + " old notifications");
        }
    }
    
    // 특정 사용자가 특정 그룹 피드를 평가했는지 확인
    public boolean isEvaluationCompleted(Long groupFeedId, Long memberId) {
        return evaluationRepository.existsByGroupFeedIdAndEvaluatorId(groupFeedId, memberId);
    }
}
