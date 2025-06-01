package NPJ.Crewer.running;

import NPJ.Crewer.member.Member;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class RunningRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    private Member runner; // 기록한 사용자

    @CreatedDate
    @Column(updatable = false, nullable = false)
    private LocalDateTime createdAt;

    @Column(updatable = false, nullable = false)
    private int totalSeconds; // 총 시간 (초)

    @Column(updatable = false, nullable = false)
    private double totalDistance; // 총 거리 (미터)

    @ElementCollection
    @CollectionTable(name = "running_record_path", joinColumns = @JoinColumn(name = "record_id"))
    @OrderColumn(name = "sequence")
    private List<LocationPoint> path = new ArrayList<>();

    @Embeddable//어노테이션을 활용해 별도 식별자 없이 RunningRecord와 합쳐져 사용
    @Builder
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @EqualsAndHashCode
    public static class LocationPoint {
        @Column(nullable = false)
        private double latitude;

        @Column(nullable = false)
        private double longitude;
    }
}
