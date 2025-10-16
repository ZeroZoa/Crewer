package NPJ.Crewer.notification.dto;

import NPJ.Crewer.notification.Notification;
import NPJ.Crewer.notification.NotificationType;
import com.fasterxml.jackson.annotation.JsonProperty;
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
    
    @JsonProperty("evaluationCompleted")
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

    /**
     * Notification 엔티티로부터 NotificationResponseDTO를 생성한다.
     */
    public static NotificationResponseDTO from(Notification notification, boolean isEvaluationCompleted) {
        return NotificationResponseDTO.builder()
                .id(notification.getId())
                .recipientNickname(notification.getRecipient().getNickname())
                .type(notification.getType())
                .title(notification.getTitle())
                .content(notification.getContent())
                .isRead(notification.isRead())
                .relatedGroupFeedId(notification.getRelatedGroupFeedId())
                .createdAt(notification.getCreatedAt())
                .isEvaluationCompleted(isEvaluationCompleted)
                .build();
    }
}
