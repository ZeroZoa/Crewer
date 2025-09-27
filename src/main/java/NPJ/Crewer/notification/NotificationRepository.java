package NPJ.Crewer.notification;

import NPJ.Crewer.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    
    List<Notification> findByRecipientOrderByCreatedAtDesc(Member recipient);
    
    List<Notification> findByRecipientAndIsReadOrderByCreatedAtDesc(Member recipient, boolean isRead);
    
    @Query("SELECT COUNT(n) FROM Notification n WHERE n.recipient = :recipient AND n.isRead = false")
    long countUnreadByRecipient(@Param("recipient") Member recipient);
    
    // 읽지 않은 알림 개수 조회 (ID로)
    int countByRecipientIdAndIsReadFalse(Long recipientId);
    
    // 특정 멤버의 모든 알림 조회 (ID로)
    List<Notification> findByRecipientIdOrderByCreatedAtDesc(Long recipientId);
    
    // 특정 날짜 이전의 알림 조회 (자동 정리용)
    List<Notification> findByCreatedAtBefore(Instant date);
}
