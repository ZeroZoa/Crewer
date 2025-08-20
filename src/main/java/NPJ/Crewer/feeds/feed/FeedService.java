package NPJ.Crewer.feeds.feed;

import NPJ.Crewer.comments.feedcomment.FeedCommentRepository;
import NPJ.Crewer.feeds.feed.dto.FeedCreateDTO;
import NPJ.Crewer.feeds.feed.dto.FeedResponseDTO;
import NPJ.Crewer.feeds.feed.dto.FeedUpdateDTO;
import NPJ.Crewer.likes.likefeed.LikeFeedRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
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
    private final MemberRepository memberRepository;

    //Feed 생성하기
    @Transactional
    public FeedResponseDTO createFeed(FeedCreateDTO feedCreateDTO, Long memberId) {

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

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
                savedFeed.getAuthor().getUsername(),
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
                    feed.getAuthor().getUsername(),
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
                feed.getAuthor().getUsername(),
                feed.getCreatedAt(),
                likesCount,
                commentsCount
        );
    }

    //Feed 수정
    @Transactional
    public FeedResponseDTO updateFeed(Long feedId, Long memberId, FeedUpdateDTO feedUpdateDTO) {
        //피드 조회 (없으면 예외 발생)
        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("Feed을 찾을 수 없습니다."));

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

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
                feed.getAuthor().getUsername(),
                feed.getCreatedAt(),
                likesCount,
                commentsCount
        );
    }

    //수정할 피드 내용 불러오기
    @Transactional(readOnly = true)
    public FeedUpdateDTO getFeedForUpdate(Long feedId, Long memberId) {
        //피드 불러오기
        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("Feed을 찾을 수 없습니다."));

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        //피드를 수정할 권한 확인 (작성자만 가능)
        if (!feed.getAuthor().getUsername().equals(member.getUsername())){
            throw new AccessDeniedException("본인이 작성한 글만 수정할 수 있습니다.");
        }

        return new FeedUpdateDTO(feed.getTitle(), feed.getContent());
    }

    //피드 삭제하기
    @Transactional
    public void deleteFeed(Long feedId, Long memberId) {

        //피드 불러오기
        Feed feed = feedRepository.findById(feedId)
                .orElseThrow(() -> new IllegalArgumentException("Feed을 찾을 수 없습니다."));

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

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
