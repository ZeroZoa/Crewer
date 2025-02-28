package NPJ.Crewer.feed;

import NPJ.Crewer.feed.dto.FeedCreateDTO;
import NPJ.Crewer.feed.dto.FeedResponseDTO;
import NPJ.Crewer.feed.dto.FeedUpdateDTO;
import NPJ.Crewer.member.Member;
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

import java.util.Optional;

@RequiredArgsConstructor
@RestController
@RequestMapping("/feeds")
public class FeedController {

    private final FeedService feedService;


    //피드 생성하기
    @PostMapping("/create")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FeedResponseDTO> createFeed(@Valid @RequestBody FeedCreateDTO feedCreateDTO,
                                                      @AuthenticationPrincipal Member member) {
        if (member == null) {
            System.out.println("에러다에러");
            throw new IllegalArgumentException("인증된 사용자가 아닙니다.");
        }
        FeedResponseDTO feedResponseDTO = feedService.createFeed(feedCreateDTO, member);
        return ResponseEntity.status(HttpStatus.CREATED).body(feedResponseDTO);
    }

    //피드 리스트 불러오기
    @GetMapping
    public ResponseEntity<Page<FeedResponseDTO>> getAllFeeds(@PageableDefault(size = 20) Pageable pageable) { //Feed를 20개씩 페이지로 불러오기

        Page<FeedResponseDTO> feeds = feedService.getAllFeeds(pageable);
        return ResponseEntity.ok(feeds);
    }

    //피드 상세 페이지 불러오기
    @GetMapping("/{feedId}")
    public ResponseEntity<FeedResponseDTO> getFeedById(@PathVariable Long feedId) {
        FeedResponseDTO feedResponseDTO = feedService.getFeedById(feedId);
        return ResponseEntity.ok(feedResponseDTO);
    }

    //수정할 피드 내용 불러오기
    @GetMapping("/{feedId}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FeedUpdateDTO> getFeedForUpdate(@PathVariable Long feedId, @AuthenticationPrincipal Member member) {
        FeedUpdateDTO feedUpdateDTO = feedService.getFeedForUpdate(feedId, member);
        return ResponseEntity.ok(feedUpdateDTO);
    }

    //피드 수정하기
    @PutMapping("/{feedId}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FeedResponseDTO> updateFeed(@PathVariable Long feedId,
                                                      @AuthenticationPrincipal Member member,
                                                      @Valid @RequestBody FeedUpdateDTO feedUpdateDTO) {
        FeedResponseDTO updatedFeed = feedService.updateFeed(feedId, member, feedUpdateDTO);
        return ResponseEntity.ok(updatedFeed);
    }


    //피드 삭제하기
    @DeleteMapping("/{feedId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> deleteFeed(@PathVariable Long feedId, @AuthenticationPrincipal Member member) {
        if (member == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build(); // 403 반환
        }

        feedService.deleteFeed(feedId, member);
        return ResponseEntity.noContent().build();
    }

}

