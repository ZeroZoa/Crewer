package NPJ.Crewer.feed;


import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RequiredArgsConstructor
@RestController
@RequestMapping("/feeds")
public class FeedController {
    private final FeedService feedService;
    private final MemberService memberService;

    @PostMapping("/create")
    public ResponseEntity<?> createFeed(@Valid @RequestBody FeedDTO feedDTO, BindingResult bindingResult) {
        //입력값 검증
        if (bindingResult.hasErrors()) {
            return ResponseEntity.badRequest().body("입력값이 올바르지 않습니다.");
        }

        //로그인 여부 확인
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인이 필요합니다.");
        }

        //현재 로그인된 사용자 가져오기
        String username = authentication.getName();
        Optional<Member> optionalMember = Optional.ofNullable(memberService.getMember(username));

        //회원 정보가 없으면 403 Forbidden 반환
        if (optionalMember.isEmpty()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("사용자 정보를 찾을 수 없습니다.");
        }

        //피드 생성
        Member member = optionalMember.get();
        Feed feed = feedService.createFeed(feedDTO.getTitle(), feedDTO.getContent(), member);

        return ResponseEntity.ok(feed);
    }

    //피드 리스트 조회 (GET /feeds)
    @GetMapping
    public ResponseEntity<List<Feed>> getAllFeeds() {
        return ResponseEntity.ok(feedService.getAllFeeds());
    }

    //특정 피드 조회 (GET /feeds/{id})
    @GetMapping("/{id}")
    public ResponseEntity<Optional<Feed>> getFeedById(@PathVariable Long id) {
        return ResponseEntity.ok(Optional.ofNullable(feedService.getFeedById(id)));
    }

    //피드 삭제 (DELETE /feeds/{id})
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteFeed(@PathVariable Long id) {
        feedService.deleteFeed(id);
        return ResponseEntity.noContent().build();
    }
}