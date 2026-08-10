package NPJ.Crewer.service.likes.likefeed;

import NPJ.Crewer.domain.likes.likefeed.LikeFeed;
import NPJ.Crewer.repository.likes.likefeed.LikeFeedRepository;

import NPJ.Crewer.domain.feeds.feed.Feed;
import NPJ.Crewer.repository.feeds.feed.FeedRepository;
import NPJ.Crewer.domain.member.Member;
import NPJ.Crewer.repository.member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class LikeFeedService {

    private final FeedRepository feedRepository;
    private final LikeFeedRepository likeFeedRepository;
    private final MemberRepository memberRepository;

    //좋아요 누르기
    @Transactional
    public long toggleLike(Long feedId, Long memberId) {
        //사용자 예외 처리
        Member liker = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

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
}