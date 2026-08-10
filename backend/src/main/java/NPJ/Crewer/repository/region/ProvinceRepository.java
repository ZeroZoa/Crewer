package NPJ.Crewer.repository.region;

import NPJ.Crewer.domain.region.Province;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProvinceRepository extends JpaRepository<Province, String> {
    
    // 모든 시/도 목록 조회 (정렬)
    List<Province> findAllByOrderByRegionNameAsc();
}
