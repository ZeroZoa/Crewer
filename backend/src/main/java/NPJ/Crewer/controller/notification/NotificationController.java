package NPJ.Crewer.controller.notification;

import NPJ.Crewer.service.notification.NotificationService;

import NPJ.Crewer.dto.notification.NotificationResponseDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<NotificationResponseDTO>> getNotifications(@AuthenticationPrincipal(expression = "id") Long memberId) {
        List<NotificationResponseDTO> notifications = notificationService.getNotificationDTOsByMember(memberId);
        return ResponseEntity.ok(notifications);
    }

    @PutMapping("/{notificationId}/read")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> markAsRead(@PathVariable Long notificationId, @AuthenticationPrincipal(expression = "id") Long memberId) {
        notificationService.markAsRead(notificationId, memberId);
        return ResponseEntity.ok().build();
    }

    // 알림 개수 조회 (읽지 않은 알림 개수)
    @GetMapping("/count")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Integer>> getNotificationCount(@AuthenticationPrincipal(expression = "id") Long memberId) {
        int unreadCount = notificationService.getUnreadNotificationCount(memberId);
        return ResponseEntity.ok(Map.of("unreadCount", unreadCount));
    }
}
