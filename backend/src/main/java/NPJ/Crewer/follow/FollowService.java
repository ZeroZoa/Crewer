package NPJ.Crewer.follow;

import NPJ.Crewer.follow.dto.FollowListResponse;
import NPJ.Crewer.follow.dto.FollowStatusResponse;
import NPJ.Crewer.global.util.MemberUtil;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import NPJ.Crewer.profile.SimpleProfileDTO;
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
    
    @Transactional
    public FollowStatusResponse follow(Long followerId, String followingUsername) {
        Member follower = MemberUtil.getMemberOrThrow(memberRepository, followerId);
        Member following = MemberUtil.getMemberByUsernameOrThrow(memberRepository, followingUsername);
        
        if (follower.getId().equals(following.getId())) {
            throw new FollowException("자기 자신을 팔로우할 수 없습니다.");
        }
        
        if (followRepository.existsByFollowerAndFollowing(follower, following)) {
            throw new FollowException("이미 팔로우 중입니다.");
        }
        
        Follow follow = new Follow(follower, following);
        followRepository.save(follow);
        
        return getFollowStatus(followerId, followingUsername);
    }
    
    @Transactional
    public FollowStatusResponse unfollow(Long followerId, String followingUsername) {
        Member follower = MemberUtil.getMemberOrThrow(memberRepository, followerId);
        Member following = MemberUtil.getMemberByUsernameOrThrow(memberRepository, followingUsername);
        
        followRepository.deleteByFollowerAndFollowing(follower, following);
        
        return getFollowStatus(followerId, followingUsername);
    }
    
    @Transactional(readOnly = true)
    public boolean isFollowing(Long followerId, String followingUsername) {
        Member follower = MemberUtil.getMemberOrThrow(memberRepository, followerId);
        Member following = MemberUtil.getMemberByUsernameOrThrow(memberRepository, followingUsername);
        
        return followRepository.existsByFollowerAndFollowing(follower, following);
    }
    
    @Transactional(readOnly = true)
    public FollowStatusResponse getFollowStatus(Long followerId, String followingUsername) {
        Member follower = MemberUtil.getMemberOrThrow(memberRepository, followerId);
        Member following = MemberUtil.getMemberByUsernameOrThrow(memberRepository, followingUsername);
        
        boolean isFollowing = followRepository.existsByFollowerAndFollowing(follower, following);
        long followerCount = followRepository.countByFollowing(following);
        long followingCount = followRepository.countByFollower(following);
        
        return FollowStatusResponse.builder()
                .isFollowing(isFollowing)
                .followerCount(followerCount)
                .followingCount(followingCount)
                .build();
    }
    
    @Transactional(readOnly = true)
    public FollowListResponse getFollowers(Long memberId) {
        Member member = MemberUtil.getMemberOrThrow(memberRepository, memberId);
        
        List<Follow> follows = followRepository.findFollowersWithMember(member);
        List<SimpleProfileDTO> followers = follows.stream()
                .map(follow -> SimpleProfileDTO.from(follow.getFollower()))
                .collect(Collectors.toList());
        
        return FollowListResponse.builder()
                .members(followers)
                .totalCount(followers.size())
                .hasNext(false)
                .build();
    }
    
    @Transactional(readOnly = true)
    public FollowListResponse getFollowing(Long memberId) {
        Member member = MemberUtil.getMemberOrThrow(memberRepository, memberId);
        
        List<Follow> follows = followRepository.findFollowingWithMember(member);
        List<SimpleProfileDTO> following = follows.stream()
                .map(follow -> SimpleProfileDTO.from(follow.getFollowing()))
                .collect(Collectors.toList());
        
        return FollowListResponse.builder()
                .members(following)
                .totalCount(following.size())
                .hasNext(false)
                .build();
    }
    
    @Transactional(readOnly = true)
    public FollowListResponse getFollowersByUsername(String username) {
        Member member = MemberUtil.getMemberByUsernameOrThrow(memberRepository, username);
        return getFollowers(member.getId());
    }
    
    @Transactional(readOnly = true)
    public FollowListResponse getFollowingByUsername(String username) {
        Member member = MemberUtil.getMemberByUsernameOrThrow(memberRepository, username);
        return getFollowing(member.getId());
    }
} 