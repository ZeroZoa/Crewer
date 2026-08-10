package NPJ.Crewer.follow;

import NPJ.Crewer.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface FollowRepository extends JpaRepository<Follow, Long> {
    
    // 팔로우 관계 확인
    boolean existsByFollowerAndFollowing(Member follower, Member following);
    
    // 특정 팔로우 관계 조회
    Optional<Follow> findByFollowerAndFollowing(Member follower, Member following);
    
    // 팔로워 목록 조회 (나를 팔로우하는 사람들)
    List<Follow> findByFollowing(Member following);
    
    // 팔로잉 목록 조회 (내가 팔로우하는 사람들)
    List<Follow> findByFollower(Member follower);
    
    // 팔로워 수 카운트
    long countByFollowing(Member following);
    
    // 팔로잉 수 카운트
    long countByFollower(Member follower);
    
    // 특정 팔로우 관계 삭제
    void deleteByFollowerAndFollowing(Member follower, Member following);
    
    // 팔로워 목록 (Member 정보 포함)
    @Query("SELECT f FROM Follow f JOIN FETCH f.follower WHERE f.following = :following")
    List<Follow> findFollowersWithMember(@Param("following") Member following);
    
    // 팔로잉 목록 (Member 정보 포함)
    @Query("SELECT f FROM Follow f JOIN FETCH f.following WHERE f.follower = :follower")
    List<Follow> findFollowingWithMember(@Param("follower") Member follower);
} 