package NPJ.Crewer.follow;

import NPJ.Crewer.follow.dto.FollowListResponse;
import NPJ.Crewer.follow.dto.FollowStatusResponse;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import NPJ.Crewer.profile.ProfileDTO;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FollowService {
    
    private final FollowRepository followRepository;
    private final MemberRepository memberRepository;
    
    // 팔로우
    @Transactional
    public FollowStatusResponse follow(Long followerId, String followingUsername) {
        Member follower = memberRepository.findById(followerId)
                .orElseThrow(() -> new EntityNotFoundException("팔로우하는 사용자를 찾을 수 없습니다."));
        
        Member following = memberRepository.findByUsername(followingUsername)
                .orElseThrow(() -> new EntityNotFoundException("팔로우할 사용자를 찾을 수 없습니다."));
        
        // 자기 자신 팔로우 방지
        if (follower.getId().equals(following.getId())) {
            throw new FollowException("자기 자신을 팔로우할 수 없습니다.");
        }
        
        // 이미 팔로우 중인지 확인
        if (followRepository.existsByFollowerAndFollowing(follower, following)) {
            throw new FollowException("이미 팔로우 중입니다.");
        }
        
        // 팔로우 관계 생성
        Follow follow = new Follow(follower, following);
        followRepository.save(follow);
        
        return getFollowStatus(followerId, followingUsername);
    }
    
    // 언팔로우
    @Transactional
    public FollowStatusResponse unfollow(Long followerId, String followingUsername) {
        Member follower = memberRepository.findById(followerId)
                .orElseThrow(() -> new EntityNotFoundException("언팔로우하는 사용자를 찾을 수 없습니다."));
        
        Member following = memberRepository.findByUsername(followingUsername)
                .orElseThrow(() -> new EntityNotFoundException("언팔로우할 사용자를 찾을 수 없습니다."));
        
        // 팔로우 관계 삭제
        followRepository.deleteByFollowerAndFollowing(follower, following);
        
        return getFollowStatus(followerId, followingUsername);
    }
    
    // 팔로우 상태 확인
    @Transactional(readOnly = true)
    public boolean isFollowing(Long followerId, String followingUsername) {
        Member follower = memberRepository.findById(followerId)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다."));
        
        Member following = memberRepository.findByUsername(followingUsername)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다."));
        
        return followRepository.existsByFollowerAndFollowing(follower, following);
    }
    
    // 팔로우 상태 응답 생성
    @Transactional(readOnly = true)
    public FollowStatusResponse getFollowStatus(Long followerId, String followingUsername) {
        Member follower = memberRepository.findById(followerId)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다."));
        
        Member following = memberRepository.findByUsername(followingUsername)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다."));
        
        boolean isFollowing = followRepository.existsByFollowerAndFollowing(follower, following);
        long followerCount = followRepository.countByFollowing(following);
        long followingCount = followRepository.countByFollower(following);
        
        return FollowStatusResponse.builder()
                .isFollowing(isFollowing)
                .followerCount(followerCount)
                .followingCount(followingCount)
                .build();
    }
    
    // 팔로워 목록 조회
    @Transactional(readOnly = true)
    public FollowListResponse getFollowers(Long memberId) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다."));
        
        List<Follow> follows = followRepository.findFollowersWithMember(member);
        List<ProfileDTO> followers = follows.stream()
                .map(follow -> createProfileDTO(follow.getFollower()))
                .collect(Collectors.toList());
        
        return FollowListResponse.builder()
                .members(followers)
                .totalCount(followers.size())
                .hasNext(false) // 페이징 미적용
                .build();
    }
    
    // 팔로잉 목록 조회
    @Transactional(readOnly = true)
    public FollowListResponse getFollowing(Long memberId) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다."));
        
        List<Follow> follows = followRepository.findFollowingWithMember(member);
        List<ProfileDTO> following = follows.stream()
                .map(follow -> createProfileDTO(follow.getFollowing()))
                .collect(Collectors.toList());
        
        return FollowListResponse.builder()
                .members(following)
                .totalCount(following.size())
                .hasNext(false) // 페이징 미적용
                .build();
    }
    
    // 사용자명으로 팔로워 목록 조회
    @Transactional(readOnly = true)
    public FollowListResponse getFollowersByUsername(String username) {
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다."));
        
        return getFollowers(member.getId());
    }
    
    // 사용자명으로 팔로잉 목록 조회
    @Transactional(readOnly = true)
    public FollowListResponse getFollowingByUsername(String username) {
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다."));
        
        return getFollowing(member.getId());
    }
    
    // ProfileDTO 생성 헬퍼 메서드
    private ProfileDTO createProfileDTO(Member member) {
        long followersCount = followRepository.countByFollowing(member);
        long followingCount = followRepository.countByFollower(member);
        
        return ProfileDTO.builder()
                .username(member.getUsername())
                .nickname(member.getNickname())
                .avatarUrl(member.getAvatarUrl())
                .temperature(member.getTemperature())
                .interests(member.getInterests())
                .followersCount((int) followersCount)
                .followingCount((int) followingCount)
                .build();
    }
} 