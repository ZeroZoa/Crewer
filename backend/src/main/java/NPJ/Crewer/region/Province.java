package NPJ.Crewer.region;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.Instant;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@EntityListeners(AuditingEntityListener.class)
@Table(name = "provinces")
public class Province {

    @Id
    @Column(length = 2)
    private String regionId; // 시/도 코드 (2자리)

    @Column(nullable = false, length = 50)
    private String regionName; // 시/도명

    @Column(nullable = false, length = 20)
    private String level; // 행정구역 레벨

    @Column(nullable = false)
    private Double latitude; // 위도

    @Column(nullable = false)
    private Double longitude; // 경도

    @Column(length = 200)
    private String geojsonFilePath; // 해당 시/도의 GeoJSON 파일 경로 (예: hangjeongdong_서울특별시_30%.json)

    @CreatedDate
    @Column(updatable = false, nullable = false)
    private Instant createdAt;

    // 생성자
    public Province(String regionId, String regionName, String level, Double latitude, Double longitude, String geojsonFilePath) {
        this.regionId = regionId;
        this.regionName = regionName;
        this.level = level;
        this.latitude = latitude;
        this.longitude = longitude;
        this.geojsonFilePath = geojsonFilePath;
    }
}
