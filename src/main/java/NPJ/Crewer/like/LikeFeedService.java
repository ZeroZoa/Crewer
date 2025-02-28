package NPJ.Crewer.like;

import NPJ.Crewer.feed.Feed;
import NPJ.Crewer.feed.FeedRepository;
import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class LikeFeedService {

    private final FeedRepository feedRepository;
    private final LikeFeedRepository likeFeedRepository;

    //좋아요 누르기
    @Transactional
    public long toggleLike(Long feedId, Member liker) {
        //좋아요할 사용자 찾기
        if (liker == null) {
            throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");
        }

        //좋아요할 피드 찾기
        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("피드를 찾을 수 없습니다."));

        //좋아요 여부 확인 후 토글
        Optional<LikeFeed> existingLike = likeFeedRepository.findByFeedAndLiker(feed, liker);

        if (existingLike.isPresent()) {
            likeFeedRepository.delete(existingLike.get()); // 이미 눌렀으면 삭제
        } else {
            LikeFeed likeFeed = LikeFeed.builder()
                    .liker(liker)
                    .feed(feed)
                    .build();
            likeFeedRepository.save(likeFeed); // 없으면 저장
        }
        return likeFeedRepository.countByFeedId(feedId);
    }

    //좋아요 수 불러오기
    @Transactional(readOnly = true)
    public long countLikes(Long feedId) {
        return likeFeedRepository.countByFeedId(feedId);
    }

    //피드를 좋아요 했는지 확인
    @Transactional(readOnly = true)
    public boolean isLikedByUser(Long feedId, Member liker) {
        if (liker == null) {
            return false;
        }

        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("해당 피드를 찾을 수 없습니다."));

        return likeFeedRepository.existsByFeedAndLiker(feed, liker);
    }
}