package NPJ.Crewer.profile;

import NPJ.Crewer.feeds.feed.Feed;
import NPJ.Crewer.feeds.feed.FeedRepository;
import NPJ.Crewer.feeds.feed.dto.FeedResponseDTO;
import NPJ.Crewer.follow.FollowRepository;
import NPJ.Crewer.global.service.FileStorageService;
import NPJ.Crewer.global.util.MemberUtil;
import NPJ.Crewer.likes.likefeed.LikeFeedRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProfileService {
    private final MemberRepository memberRepository;
    private final FeedRepository feedRepository;
    private final LikeFeedRepository likeFeedRepository;
    private final FollowRepository followRepository;
    private final FileStorageService fileStorageService;

    @Transactional(readOnly = true)
    public ProfileDTO getMyProfile(Long memberId) {
        Member member = MemberUtil.getMemberOrThrow(memberRepository, memberId);
        
        long followersCount = followRepository.countByFollowing(member);
        long followingCount = followRepository.countByFollower(member);
        
        return ProfileDTO.from(member, followersCount, followingCount);
    }

    @Transactional(readOnly = true)
    public List<FeedResponseDTO> getMyFeeds(Long memberId) {
        Member member = MemberUtil.getMemberOrThrow(memberRepository, memberId);

        return feedRepository.findByAuthor(member).stream()
                .map(feed -> new FeedResponseDTO(
                        feed.getId(),
                        feed.getTitle(),
                        feed.getContent(),
                        feed.getAuthorNickname(),
                        feed.getAuthorUsername(),
                        feed.getAuthorAvatarUrl(),
                        feed.getCreatedAt(),
                        feed.getLikesCount(),
                        feed.getCommentsCount()
                ))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<FeedResponseDTO> getMyLikedFeeds(Long memberId) {
        Member member = MemberUtil.getMemberOrThrow(memberRepository, memberId);

        return likeFeedRepository.findByLikerOrderByCreatedAtDesc(member).stream()
                .map(likeFeed -> {
                    Feed feed = likeFeed.getFeed();
                    return new FeedResponseDTO(
                            feed.getId(),
                            feed.getTitle(),
                            feed.getContent(),
                            feed.getAuthor().getNickname(),
                            feed.getAuthor().getUsername(),
                            feed.getAuthor().getProfile().getAvatarUrl(),
                            feed.getCreatedAt(),
                            feed.getLikes().size(),
                            feed.getComments().size()
                    );
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public List<String> updateInterests(Long memberId, List<String> interests) {
        Member member = MemberUtil.getMemberOrThrow(memberRepository, memberId);
        
        Profile userProfile = member.getProfile();
        if (userProfile == null) {
            throw new IllegalStateException("프로필 정보가 존재하지 않습니다.");
        }

        userProfile.updateInterests(interests);
        return userProfile.getInterests();
    }

    @Transactional
    public String updateNickname(Long memberId, String nickname) {
        Member member = MemberUtil.getMemberOrThrow(memberRepository, memberId);

        Optional<Member> existingMember = memberRepository.findByNickname(nickname);
        if (existingMember.isPresent() && !existingMember.get().getId().equals(memberId)) {
            throw new IllegalArgumentException("이미 사용 중인 닉네임입니다.");
        }

        member.updateNickname(nickname);
        return member.getNickname();
    }

    @Transactional(readOnly = true)
    public ProfileDTO getProfileByUsername(String username) {
        Member member = MemberUtil.getMemberByUsernameOrThrow(memberRepository, username);
        
        long followersCount = followRepository.countByFollowing(member);
        long followingCount = followRepository.countByFollower(member);
        
        return ProfileDTO.from(member, followersCount, followingCount);
    }

    @Transactional(readOnly = true)
    public Member getMemberByUsername(String username) {
        return MemberUtil.getMemberByUsernameOrThrow(memberRepository, username);
    }

    @Transactional
    public String uploadProfileImage(Long memberId, MultipartFile image) throws IOException {
        Member member = MemberUtil.getMemberOrThrow(memberRepository, memberId);

        String fileUrl = fileStorageService.storeProfileImage(memberId, image);

        Profile userProfile = member.getProfile();
        if (userProfile == null) {
            throw new IllegalStateException("프로필 정보가 존재하지 않습니다.");
        }
        
        userProfile.updateAvatarUrl(fileUrl);

        return fileUrl;
    }
}
