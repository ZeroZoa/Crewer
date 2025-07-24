package NPJ.Crewer.feed.normalFeed;

import NPJ.Crewer.feed.groupFeed.GroupFeedService;
import NPJ.Crewer.feed.groupFeed.dto.GroupFeedResponseDTO;
import NPJ.Crewer.feed.normalFeed.dto.FeedCreateDTO;
import NPJ.Crewer.feed.normalFeed.dto.FeedResponseDTO;
import NPJ.Crewer.feed.normalFeed.dto.FeedUpdateDTO;
import NPJ.Crewer.member.Member;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/feeds")
public class FeedController {

    private final FeedService feedService;
    private final GroupFeedService groupFeedService;


    //Feed 생성
    @PostMapping("/create")
    @PreAuthorize("isAuthenticated()") //member객체가 Null인 경우를 완전히 배제할 수 있다.
    public ResponseEntity<FeedResponseDTO> createFeed(@Valid @RequestBody FeedCreateDTO feedCreateDTO,
                                                      @AuthenticationPrincipal(expression = "id") Long memberId) {

        FeedResponseDTO feedResponseDTO = feedService.createFeed(feedCreateDTO, memberId);
        return ResponseEntity.status(HttpStatus.CREATED).body(feedResponseDTO);
    }
//    //Feed 생성
//    @PostMapping("/create")
//    @PreAuthorize("isAuthenticated()") //member객체가 Null인 경우를 완전히 배제할 수 있다.
//    public ResponseEntity<FeedResponseDTO> createFeed(@Valid @RequestBody FeedCreateDTO feedCreateDTO,
//                                                      @AuthenticationPrincipal Member member) {
//
//        FeedResponseDTO feedResponseDTO = feedService.createFeed(feedCreateDTO, member);
//        return ResponseEntity.status(HttpStatus.CREATED).body(feedResponseDTO);
//    }


    @GetMapping
    public Page<Object> getAllFeeds(@PageableDefault(size = 20) Pageable pageable) {
        // 일반 피드 불러오기
        List<FeedResponseDTO> feedList = feedService.getAllFeeds(Pageable.unpaged()).getContent();
        // 그룹 피드 불러오기
        List<GroupFeedResponseDTO> groupFeedList = groupFeedService.getAllGroupFeeds(Pageable.unpaged()).getContent();

        // 두 개의 리스트를 합치기
        List<Object> combinedFeeds = new ArrayList<>();
        combinedFeeds.addAll(feedList);
        combinedFeeds.addAll(groupFeedList);

        // 최신순 정렬
        combinedFeeds.sort((a, b) -> {
            LocalDateTime dateA = a instanceof FeedResponseDTO ? ((FeedResponseDTO) a).getCreatedAt() : ((GroupFeedResponseDTO) a).getCreatedAt();
            LocalDateTime dateB = b instanceof FeedResponseDTO ? ((FeedResponseDTO) b).getCreatedAt() : ((GroupFeedResponseDTO) b).getCreatedAt();
            return dateB.compareTo(dateA);
        });

        // 전체 데이터 개수
        int total = combinedFeeds.size();
        // 요청된 페이지에 해당하는 데이터 잘라내기
        int start = (int) pageable.getOffset();
        int end = Math.min((start + pageable.getPageSize()), total);
        List<Object> pageContent = combinedFeeds.subList(start, end);

        return new PageImpl<>(pageContent, pageable, total);
    }

    //Feed 상세 페이지 조회
    @GetMapping("/{feedId}")
    public ResponseEntity<FeedResponseDTO> getFeedById(@PathVariable Long feedId) {
        FeedResponseDTO feedResponseDTO = feedService.getFeedById(feedId);
        return ResponseEntity.ok(feedResponseDTO);
    }

    //수정할 Feed 내용 조회
    @GetMapping("/{feedId}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FeedUpdateDTO> getFeedForUpdate(@PathVariable Long feedId,
                                                          @AuthenticationPrincipal(expression = "id") Long memberId) {
        FeedUpdateDTO feedUpdateDTO = feedService.getFeedForUpdate(feedId, memberId);
        return ResponseEntity.ok(feedUpdateDTO);
    }

    //Feed 수정
    @PutMapping("/{feedId}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FeedResponseDTO> updateFeed(@PathVariable Long feedId,
                                                      @AuthenticationPrincipal(expression = "id") Long memberId,
                                                      @Valid @RequestBody FeedUpdateDTO feedUpdateDTO) {
        FeedResponseDTO updatedFeed = feedService.updateFeed(feedId, memberId, feedUpdateDTO);
        return ResponseEntity.ok(updatedFeed);
    }


    //Feed 삭제
    @DeleteMapping("/{feedId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> deleteFeed(@PathVariable Long feedId,
                                           @AuthenticationPrincipal(expression = "id") Long memberId) {


        feedService.deleteFeed(feedId, memberId);
        return ResponseEntity.noContent().build();
    }

}

