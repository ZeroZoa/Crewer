package NPJ.Crewer.evaluation;

import NPJ.Crewer.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.member.Member;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.Instant;

@Entity
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class Evaluation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "evaluator_id", nullable = false)
    private Member evaluator;  // 평가자

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "evaluated_id", nullable = false)
    private Member evaluated;  // 피평가자

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_feed_id", nullable = false)
    private GroupFeed groupFeed;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EvaluationType type;  // 평가 타입

    @CreatedDate
    @Column(updatable = false, nullable = false)
    private Instant createdAt;
}
