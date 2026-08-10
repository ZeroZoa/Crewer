package NPJ.Crewer.notification;

import NPJ.Crewer.member.Member;
import NPJ.Crewer.notification.dto.NotificationResponseDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {
    
    private final NotificationService notificationService;
    
    @GetMapping
    public ResponseEntity<List<NotificationResponseDTO>> getNotifications(Authentication authentication) {
        Member member = (Member) authentication.getPrincipal();
        List<NotificationResponseDTO> notifications = notificationService.getNotificationDTOsByMember(member.getId());
        return ResponseEntity.ok(notifications);
    }
    
    @PutMapping("/{notificationId}/read")
    public ResponseEntity<Void> markAsRead(@PathVariable Long notificationId, Authentication authentication) {
        Member member = (Member) authentication.getPrincipal();
        notificationService.markAsRead(notificationId, member.getId());
        return ResponseEntity.ok().build();
    }
    
    // 알림 개수 조회 (읽지 않은 알림 개수)
    @GetMapping("/count")
    public ResponseEntity<Map<String, Integer>> getNotificationCount(Authentication authentication) {
        Member member = (Member) authentication.getPrincipal();
        int unreadCount = notificationService.getUnreadNotificationCount(member.getId());
        return ResponseEntity.ok(Map.of("unreadCount", unreadCount));
    }
}
