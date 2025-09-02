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
@Table(name = "districts")
public class District {

    @Id
    @Column(length = 10)
    private String regionId; // 행정동 코드 (10자리)

    @Column(nullable = false, length = 100)
    private String regionName; // 행정동명

    @Column(nullable = false, length = 200)
    private String fullName; // 전체 주소

    @Column(nullable = false, length = 20)
    private String level; // 행정구역 레벨 (동/읍/면)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "city_id", nullable = false)
    private City city; // 소속 시/군/구

    @Column(nullable = false)
    private BigDecimal latitude; // 위도

    @Column(nullable = false)
    private BigDecimal longitude; // 경도

    @Column(columnDefinition = "TEXT")
    private String geojsonData; // 행정동 폴리곤 데이터 (GeoJSON Feature)

    @CreatedDate
    @Column(updatable = false, nullable = false)
    private Instant createdAt;

    // 생성자
    public District(String regionId, String regionName, String fullName, String level, 
                   City city, BigDecimal latitude, BigDecimal longitude, String geojsonData) {
        this.regionId = regionId;
        this.regionName = regionName;
        this.fullName = fullName;
        this.level = level;
        this.city = city;
        this.latitude = latitude;
        this.longitude = longitude;
        this.geojsonData = geojsonData;
    }
}
