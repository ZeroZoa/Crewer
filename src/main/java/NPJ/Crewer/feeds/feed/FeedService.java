package NPJ.Crewer.feeds.feed;

import NPJ.Crewer.feeds.feed.dto.FeedCreateDTO;
import NPJ.Crewer.feeds.feed.dto.FeedDetailResponseDTO;
import NPJ.Crewer.feeds.feed.dto.FeedResponseDTO;
import NPJ.Crewer.feeds.feed.dto.FeedUpdateDTO;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@RequiredArgsConstructor
public class FeedService {

    private final FeedRepository feedRepository;
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
                savedFeed.getAuthor().getProfile().getAvatarUrl(),
                savedFeed.getCreatedAt(),
                0,
                0
        );
    }

    //리스트 조회 최신순(페이징 20개씩)
    @Transactional(readOnly = true)
    public Page<FeedResponseDTO> getAllNewFeeds(Pageable pageable) {

        //N + 1 문제를 해결하기 위해 id를 불러와 id기준으로 댓글, 좋아요를 불러옴
        Page<Long> feedIdsPage = feedRepository.findFeedIds(pageable);
        List<Long> ids = feedIdsPage.getContent();

        if (ids.isEmpty()) {
            return Page.empty(pageable);
        }

        List<FeedResponseDTO> content = feedRepository.findFeedInfoByIds(ids);

        return new PageImpl<>(content, pageable, feedIdsPage.getTotalElements());
    }



    //Feed 리스트 조회 인기순 (페이징 20개씩)
    @Transactional(readOnly = true)
    public Page<FeedResponseDTO> getAllHotFeeds(Pageable pageable) {
        Instant sevenDaysAgo = Instant.now().minus(7, ChronoUnit.DAYS);
        //N + 1 문제를 해결하기 위해 id를 불러와 id기준으로 댓글, 좋아요를 불러옴
        Page<Long> feedIdsPage = feedRepository.findHotFeedIds(sevenDaysAgo, pageable);
        List<Long> ids = feedIdsPage.getContent();

        if (ids.isEmpty()) {
            return Page.empty(pageable);
        }

        // 2단계: ID 목록으로 엔티티와 컬렉션을 함께 조회
        List<FeedResponseDTO> content = feedRepository.findFeedInfoByIds(ids);

        // 3단계: DTO로 변환
        return new PageImpl<>(content, pageable, feedIdsPage.getTotalElements());
    }

    //메인화면에서 보여줄 Hot Feed 2개를 조회
    @Transactional(readOnly = true)
    public Page<FeedResponseDTO> getHotFeedsForMain() {
        Instant threeDaysAgo = Instant.now().minus(3, ChronoUnit.DAYS);
        Pageable topTwo = PageRequest.of(0, 2); // 0번째 페이지에서 2개만 조회

        // 1단계: Hot Feed ID 조회
        Page<Long> hotFeedIdsPage = feedRepository.findHotFeedIds(threeDaysAgo, topTwo);
        List<Long> ids = hotFeedIdsPage.getContent();

        if (ids.isEmpty()) {
            return Page.empty(topTwo);
        }

        List<FeedResponseDTO> content = feedRepository.findFeedInfoByIds(ids);

        return new PageImpl<>(content, topTwo, hotFeedIdsPage.getTotalElements());
    }



    //특정 Feed 상세 조회
    @Transactional(readOnly = true)
    public FeedDetailResponseDTO getFeedById(Long feedId, Long memberId) {

        // 수정: 새로 만든, comments만 fetch하는 메소드를 호출
        Feed feed = feedRepository.findByIdForFeedDetail(feedId)
                .orElseThrow(() -> new IllegalArgumentException("Feed를 찾을 수 없습니다."));

        Member currentMember = null;

        if (memberId != null) {
            currentMember = memberRepository.findById(memberId).orElse(null);
        }

        return new FeedDetailResponseDTO(feed, currentMember);

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
        if (!feed.getAuthor().getId().equals(member.getId())){
            throw new AccessDeniedException("본인이 작성한 글만 수정할 수 있습니다.");
        }

        //피드 수정
        feed.update(feedUpdateDTO.getTitle(), feedUpdateDTO.getContent());

        return new FeedResponseDTO(feed);
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

        //수정 권한 확인 (작성자만 가능)
        if (!feed.getAuthor().getId().equals(member.getId())){
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

        //수정 권한 확인 (작성자만 가능)
        if (!feed.getAuthor().getId().equals(member.getId())){
            throw new AccessDeniedException("본인이 작성한 글만 수정할 수 있습니다.");
        }

        feedRepository.delete(feed);
    }
}
