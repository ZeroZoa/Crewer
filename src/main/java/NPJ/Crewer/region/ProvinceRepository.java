package NPJ.Crewer.region;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProvinceRepository extends JpaRepository<Province, String> {
    
    // 모든 시/도 목록 조회 (정렬)
    List<Province> findAllByOrderByRegionNameAsc();
    
    // 시/도명으로 검색 (Fetch Join으로 N+1 문제 해결)
    @Query("SELECT p FROM Province p WHERE p.regionName LIKE %:regionName% ORDER BY p.regionName ASC")
    List<Province> findByRegionNameContainingIgnoreCase(@Param("regionName") String regionName);
}
