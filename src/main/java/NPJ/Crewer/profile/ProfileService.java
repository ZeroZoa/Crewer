package NPJ.Crewer.profile;

import NPJ.Crewer.feed.normalFeed.Feed;
import NPJ.Crewer.feed.normalFeed.FeedRepository;
import NPJ.Crewer.feed.normalFeed.dto.FeedResponseDTO;
import NPJ.Crewer.like.likeFeed.LikeFeedRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
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


    //사용자의 프로필 정보 조회
    @Transactional(readOnly = true)
    public ProfileDTO getProfile(Member member) {
        return new ProfileDTO(
                member.getUsername(),
                member.getNickname(),
                member.getAvatarUrl()
        );
    }

    @Transactional(readOnly = true)
    public List<FeedResponseDTO> getFeedsByUser(Member author) {
        return feedRepository.findByAuthorOrderByCreatedAtDesc(author).stream()
                .map(feed -> new FeedResponseDTO(
                        feed.getId(),
                        feed.getTitle(),
                        feed.getContent(),
                        feed.getAuthor().getNickname(),
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
    public List<FeedResponseDTO> getLikedFeeds(Member liker) {
        return likeFeedRepository.findByLikerOrderByCreatedAtDesc(liker).stream()
                .map(likeFeed -> {
                    Feed feed = likeFeed.getFeed();
                    return new FeedResponseDTO(
                            feed.getId(),
                            feed.getTitle(),
                            feed.getContent(),
                            feed.getAuthor().getNickname(),
                            feed.getCreatedAt(),
                            feedRepository.countLikesByFeedId(feed.getId()), // 좋아요 개수
                            feedRepository.countCommentsByFeedId(feed.getId()) // 댓글 개수
                    );
                })
                .collect(Collectors.toList());
    }
}
