package NPJ.Crewer.chat.chatroom;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.GenericGenerator;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;


@Entity
@Getter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
@Inheritance(strategy = InheritanceType.JOINED)
public class ChatRoom {

    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private int maxParticipants; //채팅방 최대 인원 수

    @Column(nullable = false)
    private int currentParticipants = 0; //현재 참가 인원 (기본값 0)

    @Enumerated(EnumType.STRING)
    private ChatRoomType type;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public enum ChatRoomType{
        DIRECT,
        GROUP
    }

    public void updateMaxParticipants(int newMaxParticipants) {
        if (newMaxParticipants < currentParticipants) {
            throw new IllegalStateException("현재 참가 인원보다 적게 설정할 수 없습니다.");
        }
        this.maxParticipants = newMaxParticipants;
    }

    // 신규 참가자가 추가되면 currentParticipants 값을 1 증가시키는 메서드
    public void addParticipant() {
        if (maxParticipants > currentParticipants) {
            this.currentParticipants++;
        } else {
            throw new IllegalStateException("정원이 초과되어 참가할 수 없습니다.");
        }
    }

    // 참가자가 나갈 경우 currentParticipants 값을 1 감소시키는 메서드 (필요 시 구현)
    public void removeParticipant() {
        if (this.currentParticipants > 0) {
            this.currentParticipants--;
        }
    }
}