package NPJ.Crewer.region;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.Instant;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@EntityListeners(AuditingEntityListener.class)
@Table(name = "cities")
public class City {

    @Id
    @Column(length = 5)
    private String regionId; // 시/군/구 코드 (5자리)

    @Column(nullable = false, length = 100)
    private String regionName; // 시/군/구명

    @Column(nullable = false, length = 200)
    private String fullName; // 전체 주소 (예: 서울특별시 강남구)

    @Column(nullable = false, length = 20)
    private String level; // 행정구역 레벨 (시/군/구)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "province_id", nullable = false)
    private Province province; // 소속 시/도

    @Column(nullable = false)
    private BigDecimal latitude; // 위도

    @Column(nullable = false)
    private BigDecimal longitude; // 경도

    @CreatedDate
    @Column(updatable = false, nullable = false)
    private Instant createdAt;

    // 생성자
    public City(String regionId, String regionName, String fullName, String level,
                Province province, BigDecimal latitude, BigDecimal longitude) {
        this.regionId = regionId;
        this.regionName = regionName;
        this.fullName = fullName;
        this.level = level;
        this.province = province;
        this.latitude = latitude;
        this.longitude = longitude;
    }
}
