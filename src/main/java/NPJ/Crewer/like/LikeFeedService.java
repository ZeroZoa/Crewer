package NPJ.Crewer.like;

import NPJ.Crewer.feed.Feed;
import NPJ.Crewer.feed.FeedRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class LikeFeedService {
    private final LikeFeedRepository likeFeedRepository;
    private final MemberRepository memberRepository;
    private final FeedRepository feedRepository;

    @Transactional
    public void toggleLike(Long feedId, String username) {
        //로그인된 사용자 정보 가져오기
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("유효하지 않은 Member ID입니다."));

        //피드 정보 가져오기
        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("유효하지 않은 Feed ID입니다."));

        //좋아요 여부 확인 후 토글
        Optional<LikeFeed> existingLike = likeFeedRepository.findByFeedAndMember(feed, member);

        if (existingLike.isPresent()) {
            likeFeedRepository.delete(existingLike.get()); // 이미 눌렀으면 삭제
        } else {
            LikeFeed likeFeed = LikeFeed.builder()
                    .member(member)
                    .feed(feed)
                    .build();
            likeFeedRepository.save(likeFeed); // 없으면 저장
        }
        long likeCount = likeFeedRepository.countByFeedId(feedId);
    }

    public long countLikes(Long feedId) {
        return likeFeedRepository.countByFeedId(feedId); // ✅ 특정 피드의 좋아요 개수 반환
    }

    public boolean isLikedByUser(Long feedId, String username) {
        Optional<Member> optionalMember = memberRepository.findByUsername(username);
        Optional<Feed> optionalFeed = feedRepository.findById(feedId);

        if (optionalMember.isEmpty() || optionalFeed.isEmpty()) {
            return false; // 유효하지 않은 요청은 false 처리
        }

        Member member = optionalMember.get();
        Feed feed = optionalFeed.get();

        return likeFeedRepository.existsByMemberAndFeed(member, feed);
    }
}