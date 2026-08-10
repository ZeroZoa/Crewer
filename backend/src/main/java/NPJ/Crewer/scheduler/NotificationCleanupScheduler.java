package NPJ.Crewer.scheduler;

import NPJ.Crewer.notification.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class NotificationCleanupScheduler {
    
    private final NotificationService notificationService;
    
    @Scheduled(cron = "0 0 2 * * ?")
    public void cleanupOldNotifications() {
        try {
            notificationService.deleteOldNotifications();
            log.info("Old notifications cleanup completed");
        } catch (Exception e) {
            log.error("Failed to cleanup old notifications: {}", e.getMessage(), e);
        }
    }
}
