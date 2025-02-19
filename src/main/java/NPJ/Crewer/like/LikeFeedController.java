package NPJ.Crewer.like;

import NPJ.Crewer.feed.FeedRepository;
import NPJ.Crewer.feed.FeedService;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/feeds/{feedId}/like")
@RequiredArgsConstructor
public class LikeFeedController {
    private final LikeFeedService likeFeedService;
    private final MemberService memberService;

    @PostMapping
    public ResponseEntity<?> toggleLike(@PathVariable Long feedId) {
        //로그인 여부 확인
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인이 필요합니다.");
        }

        //현재 로그인된 사용자 가져오기
        String username = authentication.getName();
        Optional<Member> optionalMember = Optional.ofNullable(memberService.getMember(username));
        if (optionalMember.isEmpty()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("사용자 정보를 찾을 수 없습니다.");
        }

        //좋아요 실행
        likeFeedService.toggleLike(feedId, username);
        return ResponseEntity.ok("좋아요 상태 변경 완료");
    }

    @GetMapping("/count")
    public ResponseEntity<Long> getLikeCount(@PathVariable Long feedId) {
        long count = likeFeedService.countLikes(feedId);
        return ResponseEntity.ok(count);
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Boolean>> getLikeStatus(@PathVariable Long feedId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            return ResponseEntity.ok(Map.of("liked", false)); // 로그인 안한 사용자 -> 무조건 false
        }

        String username = authentication.getName();
        boolean isLiked = likeFeedService.isLikedByUser(feedId, username);
        return ResponseEntity.ok(Map.of("liked", isLiked));
    }
}