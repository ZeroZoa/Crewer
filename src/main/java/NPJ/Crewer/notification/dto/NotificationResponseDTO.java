package NPJ.Crewer.notification.dto;

import NPJ.Crewer.notification.Notification;
import NPJ.Crewer.notification.NotificationType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationResponseDTO {
    private Long id;
    private String recipientNickname;
    private NotificationType type;
    private String title;
    private String content;
    private boolean isRead;
    private Long relatedGroupFeedId;
    private Instant createdAt;
    private boolean isEvaluationCompleted;

    public NotificationResponseDTO(Notification notification) {
        this.id = notification.getId();
        this.recipientNickname = notification.getRecipient().getNickname();
        this.type = notification.getType();
        this.title = notification.getTitle();
        this.content = notification.getContent();
        this.isRead = notification.isRead();
        this.relatedGroupFeedId = notification.getRelatedGroupFeedId();
        this.createdAt = notification.getCreatedAt();
        this.isEvaluationCompleted = false; // 기본값, 별도로 설정 필요
    }
}
