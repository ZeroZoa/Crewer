package NPJ.Crewer.feed.normalFeed;

import NPJ.Crewer.comment.feedComment.FeedCommentRepository;
import NPJ.Crewer.feed.normalFeed.dto.FeedCreateDTO;
import NPJ.Crewer.feed.normalFeed.dto.FeedResponseDTO;
import NPJ.Crewer.feed.normalFeed.dto.FeedUpdateDTO;
import NPJ.Crewer.like.likeFeed.LikeFeedRepository;
import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class FeedService {

    private final FeedRepository feedRepository;
    private final FeedCommentRepository feedCommentRepository;
    private final LikeFeedRepository likeFeedRepository;

    //Feed 생성하기
    @Transactional
    public FeedResponseDTO createFeed(FeedCreateDTO feedCreateDTO, Member member) {
        //사용자 예외 처리
        if (member == null) {
            throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");
        }

        Feed feed = Feed.builder()
                .title(feedCreateDTO.getTitle())
                .content(feedCreateDTO.getContent())
                .author(member)
                .build();

        Feed savedFeed = feedRepository.save(feed);

        return new FeedResponseDTO(
                savedFeed.getId(),
                savedFeed.getTitle(),
                savedFeed.getContent(),
                savedFeed.getAuthor().getNickname(),
                savedFeed.getCreatedAt(),
                0,
                0
        );
    }

    //메인 페이지 Feed 리스트 조회 (페이징 20개씩)
    @Transactional(readOnly = true)
    public Page<FeedResponseDTO> getAllFeeds(Pageable pageable) {
        return feedRepository.findAll(pageable).map(feed -> {
            int likesCount = feedRepository.countLikesByFeedId(feed.getId()); // 좋아요 개수
            int commentsCount = feedRepository.countCommentsByFeedId(feed.getId()); // 댓글 개수

            return new FeedResponseDTO(
                    feed.getId(),
                    feed.getTitle(),
                    feed.getContent(),
                    feed.getAuthor().getNickname(),
                    feed.getCreatedAt(),
                    likesCount,
                    commentsCount
            );
        });
    }

    //특정 Feed 상세 조회
    @Transactional(readOnly = true)
    public FeedResponseDTO getFeedById(Long feedId) {
        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("Feed를 찾을 수 없습니다."));

        int likesCount = feedRepository.countLikesByFeedId(feedId); // 좋아요 개수
        int commentsCount = feedRepository.countCommentsByFeedId(feedId); // 댓글 개수

        return new FeedResponseDTO(
                feed.getId(),
                feed.getTitle(),
                feed.getContent(),
                feed.getAuthor().getNickname(),
                feed.getCreatedAt(),
                likesCount,
                commentsCount
        );
    }

    //Feed 수정
    @Transactional
    public FeedResponseDTO updateFeed(Long feedId, Member member, FeedUpdateDTO feedUpdateDTO) {
        //피드 조회 (없으면 예외 발생)
        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("Feed을 찾을 수 없습니다."));

        //수정 권한 확인 (작성자만 가능)
        if (!feed.getAuthor().getUsername().equals(member.getUsername())){
            throw new AccessDeniedException("본인이 작성한 글만 수정할 수 있습니다.");
        }

        //피드 수정
        feed.update(feedUpdateDTO.getTitle(), feedUpdateDTO.getContent());

        int likesCount = feedRepository.countLikesByFeedId(feedId);
        int commentsCount = feedRepository.countCommentsByFeedId(feedId);

        return new FeedResponseDTO(
                feed.getId(),
                feed.getTitle(),
                feed.getContent(),
                feed.getAuthor().getNickname(),
                feed.getCreatedAt(),
                likesCount,
                commentsCount
        );
    }

    //수정할 피드 내용 불러오기
    @Transactional(readOnly = true)
    public FeedUpdateDTO getFeedForUpdate(Long feedId, Member member) {
        //피드 불러오기
        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("Feed을 찾을 수 없습니다."));

        //피드를 수정할 권한 확인 (작성자만 가능)
        if (!feed.getAuthor().getUsername().equals(member.getUsername())){
            throw new AccessDeniedException("본인이 작성한 글만 수정할 수 있습니다.");
        }

        return new FeedUpdateDTO(feed.getTitle(), feed.getContent());
    }

    //피드 삭제하기
    @Transactional
    public void deleteFeed(Long feedId, Member member) {
        //피드 불러오기
        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("Feed을 찾을 수 없습니다."));

        //피드를 삭제 권한 확인 (작성자만 가능)
        if (!feed.getAuthor().getUsername().equals(member.getUsername())) {
            throw new AccessDeniedException("본인이 작성한 글만 삭제할 수 있습니다.");
        }

        //1. 해당 피드의 모든 좋아요 삭제
        likeFeedRepository.deleteByFeedId(feedId);

        //2. 해당 피드의 모든 댓글 삭제
        feedCommentRepository.deleteByFeedId(feedId);

        //3. 피드 삭제
        feedRepository.delete(feed);
    }

}
