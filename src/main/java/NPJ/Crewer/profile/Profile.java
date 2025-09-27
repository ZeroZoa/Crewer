package NPJ.Crewer.profile;


import NPJ.Crewer.member.Member;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@EntityListeners(AuditingEntityListener.class)
public class Profile {

    @Id
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "member_id")
    private Member member;

    @Column(nullable = false)
    private String avatarUrl;

    @Column(nullable = false)
    private double temperature;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "member_interests", joinColumns = @JoinColumn(name = "member_id"))
    @Column(name = "interest")
    @Builder.Default
    private List<String> interests = new ArrayList<>();

    @CreatedDate
    @Column(updatable = false, nullable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    private Instant updatedAt;

    public Profile(Member member) {
        this.member = member;
        this.avatarUrl = "/images/default-avatar.png";
        this.temperature = 36.5;
    }

    public void updateInterests(List<String> newInterests) {
        this.interests.clear();
        if (newInterests != null) {
            this.interests.addAll(newInterests);
        }
    }

    public void updateAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public void updateTemperature(double change) {
        this.temperature = Math.max(0.0, Math.min(100.0, this.temperature + change));
    }
}
