package NPJ.Crewer.repository.follow;

import NPJ.Crewer.domain.follow.Follow;

import NPJ.Crewer.domain.member.Member;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
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

    // 팔로워 목록 (Member + Profile 정보까지 fetch join, 페이지네이션)
    @Query(value = "SELECT f FROM Follow f JOIN FETCH f.follower m JOIN FETCH m.profile WHERE f.following = :following",
           countQuery = "SELECT COUNT(f) FROM Follow f WHERE f.following = :following")
    Page<Follow> findFollowersWithMember(@Param("following") Member following, Pageable pageable);

    // 팔로잉 목록 (Member + Profile 정보까지 fetch join, 페이지네이션)
    @Query(value = "SELECT f FROM Follow f JOIN FETCH f.following m JOIN FETCH m.profile WHERE f.follower = :follower",
           countQuery = "SELECT COUNT(f) FROM Follow f WHERE f.follower = :follower")
    Page<Follow> findFollowingWithMember(@Param("follower") Member follower, Pageable pageable);

    // viewer가 candidates 중 이미 팔로우 중인 대상 목록 (isFollowingByMe 벌크 계산용)
    List<Follow> findByFollowerAndFollowingIn(Member follower, List<Member> candidates);
} 