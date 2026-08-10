package NPJ.Crewer.notification;

import NPJ.Crewer.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    
    List<Notification> findByRecipientOrderByCreatedAtDesc(Member recipient);
    
    // 읽지 않은 알림 개수 조회 (ID로)
    int countByRecipientIdAndIsReadFalse(Long recipientId);
    
    // 특정 날짜 이전의 알림 조회 (자동 정리용)
    List<Notification> findByCreatedAtBefore(Instant date);
}
