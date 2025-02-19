package NPJ.Crewer.feed;

import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;


@RequiredArgsConstructor
@Service
public class FeedService {
    private final FeedRepository feedRepository;

    @Transactional
    public Feed createFeed(String title, String content, Member member) {
        if (member == null) {
            throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");
        }
        // 피드 생성
        Feed feed = Feed.builder()
                .title(title)
                .content(content)
                .author(member)
                .build();

        return feedRepository.save(feed);
    }


    public List<Feed> getAllFeeds() {
        return feedRepository.findAll();
    }


    public Feed getFeedById(Long id) {
        return feedRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Feed not found"));
    }


    @Transactional
    public void deleteFeed(Long id) {
        feedRepository.deleteById(id);
    }

    @Transactional
    public Feed editFeed(Feed feed, String title, String content){
        feed.setTitle(title);
        feed.setContent(content);
        return feedRepository.save(feed);
    }
}
