package NPJ.Crewer.profile;

import NPJ.Crewer.feeds.feed.Feed;
import NPJ.Crewer.feeds.feed.FeedRepository;
import NPJ.Crewer.feeds.feed.dto.FeedResponseDTO;
import NPJ.Crewer.follow.FollowRepository;
import NPJ.Crewer.likes.likefeed.LikeFeedRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProfileService {
    private final MemberRepository memberRepository;
    private final FeedRepository feedRepository;
    private final LikeFeedRepository likeFeedRepository;
    private final FollowRepository followRepository;


    //사용자의 프로필 정보 조회
    @Transactional(readOnly = true)
    public ProfileDTO getMyProfile(Long memberId) {

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // 팔로워/팔로잉 수 계산
        long followersCount = followRepository.countByFollowing(member);
        long followingCount = followRepository.countByFollower(member);

        return ProfileDTO.builder()
                .username(member.getUsername())
                .nickname(member.getNickname())
                .avatarUrl(member.getProfile().getAvatarUrl())
                .temperature(member.getProfile().getTemperature())
                .interests(member.getProfile().getInterests())
                .followersCount((int) followersCount)
                .followingCount((int) followingCount)
                .build();
    }

    @Transactional(readOnly = true)
    public List<FeedResponseDTO> getMyFeeds(Long memberId) {

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        return feedRepository.findByAuthorOrderByCreatedAtDesc(member).stream()
                .map(feed -> new FeedResponseDTO(
                        feed.getId(),
                        feed.getTitle(),
                        feed.getContent(),
                        feed.getAuthor().getNickname(),
                        feed.getAuthor().getUsername(),
                        feed.getCreatedAt(),
                        feedRepository.countLikesByFeedId(feed.getId()), // 좋아요 개수
                        feedRepository.countCommentsByFeedId(feed.getId()) // 댓글 개수
                ))
                .collect(Collectors.toList());
    }

    /**
     * 사용자가 좋아요한 피드 목록 조회 (DTO 변환)
     */
    @Transactional(readOnly = true)
    public List<FeedResponseDTO> getMyLikedFeeds(Long memberId) {

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        return likeFeedRepository.findByLikerOrderByCreatedAtDesc(member).stream()
                .map(likeFeed -> {
                    Feed feed = likeFeed.getFeed();
                    return new FeedResponseDTO(
                            feed.getId(),
                            feed.getTitle(),
                            feed.getContent(),
                            feed.getAuthor().getNickname(),
                            feed.getAuthor().getUsername(),
                            feed.getCreatedAt(),
                            feedRepository.countLikesByFeedId(feed.getId()), // 좋아요 개수
                            feedRepository.countCommentsByFeedId(feed.getId()) // 댓글 개수
                    );
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public List<String> updateInterests(Long memberId, List<String> interests) {
        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        Profile userProfile = member.getProfile();
        if (userProfile == null) {
            throw new IllegalStateException("프로필 정보가 존재하지 않습니다.");
        }

        userProfile.updateInterests(interests);

        return userProfile.getInterests();
    }

    //사용자명으로 프로필 정보 조회
    @Transactional(readOnly = true)
    public ProfileDTO getProfileByUsername(String username) {
        //사용자 예외 처리
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // 팔로워/팔로잉 수 계산
        long followersCount = followRepository.countByFollowing(member);
        long followingCount = followRepository.countByFollower(member);

        return ProfileDTO.builder()
                .username(member.getUsername())
                .nickname(member.getNickname())
                .avatarUrl(member.getProfile().getAvatarUrl())
                .temperature(member.getProfile().getTemperature())
                .interests(member.getProfile().getInterests())
                .followersCount((int) followersCount)
                .followingCount((int) followingCount)
                .build();
    }

    //사용자명으로 Member 엔티티 조회
    @Transactional(readOnly = true)
    public Member getMemberByUsername(String username) {
        return memberRepository.findByUsername(username)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));
    }
}
