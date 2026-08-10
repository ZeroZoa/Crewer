package NPJ.Crewer.region;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DistrictRepository extends JpaRepository<District, String> {
    
    @Query("SELECT d FROM District d JOIN FETCH d.city WHERE d.city.regionId = :cityId AND d.regionName LIKE %:query%")
    List<District> findByCityIdAndRegionNameContaining(@Param("cityId") String cityId, @Param("query") String query);
    
    // 특정 시/도 내에서 행정동명으로 검색 (자동완성용)
    @Query("SELECT d FROM District d JOIN FETCH d.city JOIN FETCH d.city.province WHERE d.city.province.regionId = :provinceId AND d.regionName LIKE %:query%")
    List<District> findByProvinceIdAndRegionNameContaining(@Param("provinceId") String provinceId, @Param("query") String query);
    
    // 특정 시/도 내의 모든 행정동 조회
    @Query("SELECT d FROM District d JOIN FETCH d.city JOIN FETCH d.city.province WHERE d.city.province.regionId = :provinceId ORDER BY d.regionName ASC")
    List<District> findByCityProvinceRegionIdOrderByRegionNameAsc(@Param("provinceId") String provinceId);
    
    // 특정 시/군/구 내에서 전체 주소로 검색
    @Query("SELECT d FROM District d WHERE d.city.regionId = :cityId AND d.fullName LIKE %:query%")
    List<District> findByCityIdAndFullNameContaining(@Param("cityId") String cityId, @Param("query") String query);
    
    // 특정 시/군/구의 모든 행정동 조회
    List<District> findByCityRegionIdOrderByRegionNameAsc(String cityId);
    
    // 행정동 ID로 상세 정보 조회
    Optional<District> findByRegionId(String regionId);
}
