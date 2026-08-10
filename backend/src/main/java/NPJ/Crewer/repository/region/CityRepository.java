package NPJ.Crewer.region;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CityRepository extends JpaRepository<City, String> {
    
    // 특정 시/도 내의 모든 시/군/구 조회 (Fetch Join으로 N+1 문제 해결)
    @Query("SELECT c FROM City c JOIN FETCH c.province WHERE c.province.regionId = :provinceId ORDER BY c.regionName ASC")
    List<City> findByProvinceRegionIdWithProvince(@Param("provinceId") String provinceId);
    
    // 시/군/구명으로 검색
    List<City> findByRegionNameContainingIgnoreCase(String regionName);
    
    // 특정 시/도 내에서 시/군/구명으로 검색
    List<City> findByProvinceRegionIdAndRegionNameContainingIgnoreCase(String provinceId, String regionName);
}
