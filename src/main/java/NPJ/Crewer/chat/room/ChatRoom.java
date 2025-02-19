package NPJ.Crewer.chat.room;

import NPJ.Crewer.chat.participant.ChatParticipant;
import NPJ.Crewer.member.Member;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class) // 생성 시간 자동 관리
public class ChatRoom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // UUID → Long 변경
    private Long id;

    @Column(nullable = false)
    private String name; // 채팅방 이름

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ChatRoomType type; // 채팅방 타입 (GROUP, PRIVATE)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    private Member owner; // 채팅방 방장

    @OneToMany(mappedBy = "chatRoom", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ChatParticipant> participants = new HashSet<>(); // 참가자 목록

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt; // 생성 시간 자동 설정

    @LastModifiedDate
    @Column(nullable = false)
    private LocalDateTime lastMessageAt; // 마지막 메시지 시간 (정렬용)
}