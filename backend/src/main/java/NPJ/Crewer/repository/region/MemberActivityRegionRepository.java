package NPJ.Crewer.region;

import NPJ.Crewer.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MemberActivityRegionRepository extends JpaRepository<MemberActivityRegion, Long> {
    
    // 사용자의 활동 지역 조회
    Optional<MemberActivityRegion> findByMember(Member member);
    
    // 사용자 ID로 활동 지역 조회
    Optional<MemberActivityRegion> findByMemberId(Long memberId);
    
    // 사용자의 활동 지역 존재 여부 확인
    boolean existsByMember(Member member);
}
