package NPJ.Crewer.repository.region;

import NPJ.Crewer.domain.region.MemberActivityRegion;

import NPJ.Crewer.domain.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MemberActivityRegionRepository extends JpaRepository<MemberActivityRegion, Long> {
    
    // 사용자의 활동 지역 조회
    Optional<MemberActivityRegion> findByMember(Member member);
}
