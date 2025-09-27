package NPJ.Crewer.scheduler;

import NPJ.Crewer.notification.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class NotificationCleanupScheduler {
    
    private final NotificationService notificationService;
    
    // 매일 새벽 2시에 실행 (1주일 이상 된 알림 자동 삭제)
    @Scheduled(cron = "0 0 2 * * ?")
    public void cleanupOldNotifications() {
        try {
            notificationService.deleteOldNotifications();
        } catch (Exception e) {
            System.err.println("Failed to cleanup old notifications: " + e.getMessage());
        }
    }
}
