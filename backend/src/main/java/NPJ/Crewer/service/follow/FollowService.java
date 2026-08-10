package NPJ.Crewer.service.follow;

import NPJ.Crewer.domain.follow.Follow;
import NPJ.Crewer.domain.follow.FollowException;
import NPJ.Crewer.repository.follow.FollowRepository;

import NPJ.Crewer.dto.follow.FollowListResponse;
import NPJ.Crewer.dto.follow.FollowStatusResponse;
import NPJ.Crewer.global.util.MemberUtil;
import NPJ.Crewer.domain.member.Member;
import NPJ.Crewer.repository.member.MemberRepository;
import NPJ.Crewer.domain.profile.SimpleProfileDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.function.Function;
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
    public FollowListResponse getFollowers(Long memberId, Long viewerId, Pageable pageable) {
        Member member = MemberUtil.getMemberOrThrow(memberRepository, memberId);
        Page<Follow> page = followRepository.findFollowersWithMember(member, pageable);
        return toFollowListResponse(page, Follow::getFollower, viewerId);
    }

    @Transactional(readOnly = true)
    public FollowListResponse getFollowing(Long memberId, Long viewerId, Pageable pageable) {
        Member member = MemberUtil.getMemberOrThrow(memberRepository, memberId);
        Page<Follow> page = followRepository.findFollowingWithMember(member, pageable);
        return toFollowListResponse(page, Follow::getFollowing, viewerId);
    }

    @Transactional(readOnly = true)
    public FollowListResponse getFollowersByUsername(String username, Long viewerId, Pageable pageable) {
        Member member = MemberUtil.getMemberByUsernameOrThrow(memberRepository, username);
        return getFollowers(member.getId(), viewerId, pageable);
    }

    @Transactional(readOnly = true)
    public FollowListResponse getFollowingByUsername(String username, Long viewerId, Pageable pageable) {
        Member member = MemberUtil.getMemberByUsernameOrThrow(memberRepository, username);
        return getFollowing(member.getId(), viewerId, pageable);
    }

    // Follow 목록 페이지를 SimpleProfileDTO 목록으로 변환하면서, viewer의 팔로우 여부를 벌크로 한 번에 계산한다 (N+1 방지)
    private FollowListResponse toFollowListResponse(Page<Follow> page, Function<Follow, Member> memberExtractor, Long viewerId) {
        List<Member> listedMembers = page.getContent().stream()
                .map(memberExtractor)
                .collect(Collectors.toList());

        Set<Long> followingByViewerIds = getFollowingIds(viewerId, listedMembers);

        List<SimpleProfileDTO> members = listedMembers.stream()
                .map(m -> SimpleProfileDTO.from(m, followingByViewerIds.contains(m.getId())))
                .collect(Collectors.toList());

        return FollowListResponse.builder()
                .members(members)
                .totalCount((int) page.getTotalElements())
                .hasNext(page.hasNext())
                .build();
    }

    // viewer가 candidates 중 이미 팔로우 중인 member의 id 집합을 한 번의 쿼리로 계산한다
    private Set<Long> getFollowingIds(Long viewerId, List<Member> candidates) {
        if (candidates.isEmpty()) {
            return Collections.emptySet();
        }
        Member viewer = MemberUtil.getMemberOrThrow(memberRepository, viewerId);
        return followRepository.findByFollowerAndFollowingIn(viewer, candidates).stream()
                .map(f -> f.getFollowing().getId())
                .collect(Collectors.toSet());
    }
} 