package NPJ.Crewer.feeds.feed;

import NPJ.Crewer.feeds.feed.dto.FeedDetailResponseDTO;
import NPJ.Crewer.feeds.feed.dto.FeedCreateDTO;
import NPJ.Crewer.feeds.feed.dto.FeedResponseDTO;
import NPJ.Crewer.feeds.feed.dto.FeedUpdateDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RequiredArgsConstructor
@RestController
@RequestMapping("/feeds")
public class FeedController {

    private final FeedService feedService;


    //Feed 생성
    @PostMapping("/create")
    @PreAuthorize("isAuthenticated()") //member객체가 Null인 경우를 완전히 배제할 수 있다.
    public ResponseEntity<FeedResponseDTO> createFeed(@Valid @RequestBody FeedCreateDTO feedCreateDTO,
                                                      @AuthenticationPrincipal(expression = "id") Long memberId) {

        FeedResponseDTO feedResponseDTO = feedService.createFeed(feedCreateDTO, memberId);
        return ResponseEntity.status(HttpStatus.CREATED).body(feedResponseDTO);
    }


    @GetMapping("/new")
    public ResponseEntity<Page<FeedResponseDTO>> getAllNewFeeds(@PageableDefault(size = 20) Pageable pageable) {
        // 피드 최신순 불러오기
        Page<FeedResponseDTO> feedList = feedService.getAllNewFeeds(pageable);

        return ResponseEntity.ok(feedList);
    }

    @GetMapping("/popular")
    public ResponseEntity<Page<FeedResponseDTO>> getAllPolularFeeds(@PageableDefault(size = 20) Pageable pageable) {
        // 피드 인기순 불러오기
        Page<FeedResponseDTO> feedList = feedService.getAllHotFeeds(pageable);

        return ResponseEntity.ok(feedList);
    }


    @GetMapping("/toptwo")
    public ResponseEntity<Page<FeedResponseDTO>> getHotFeedsForMain() {
        Page<FeedResponseDTO> topTwoFeeds = feedService.getHotFeedsForMain();
        return ResponseEntity.ok(topTwoFeeds);
    }

    //Feed 상세 페이지 조회
    @GetMapping("/{feedId}")
    public ResponseEntity<FeedDetailResponseDTO> getFeedById(@PathVariable("feedId") Long feedId,
                                                             @AuthenticationPrincipal(expression = "id") Long memberId) {
        FeedDetailResponseDTO feed = feedService.getFeedById(feedId, memberId);
        return ResponseEntity.ok(feed);
    }

    //수정할 Feed 내용 조회
    @GetMapping("/{feedId}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FeedUpdateDTO> getFeedForUpdate(@PathVariable("feedId") Long feedId,
                                                          @AuthenticationPrincipal(expression = "id") Long memberId) {
        FeedUpdateDTO feedUpdateDTO = feedService.getFeedForUpdate(feedId, memberId);
        return ResponseEntity.ok(feedUpdateDTO);
    }

    //Feed 수정
    @PutMapping("/{feedId}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FeedResponseDTO> updateFeed(@PathVariable("feedId") Long feedId,
                                                      @AuthenticationPrincipal(expression = "id") Long memberId,
                                                      @Valid @RequestBody FeedUpdateDTO feedUpdateDTO) {
        FeedResponseDTO updatedFeed = feedService.updateFeed(feedId, memberId, feedUpdateDTO);
        return ResponseEntity.ok(updatedFeed);
    }


    //Feed 삭제
    @DeleteMapping("/{feedId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> deleteFeed(@PathVariable("feedId") Long feedId,
                                           @AuthenticationPrincipal(expression = "id") Long memberId) {


        feedService.deleteFeed(feedId, memberId);
        return ResponseEntity.noContent().build();
    }

}