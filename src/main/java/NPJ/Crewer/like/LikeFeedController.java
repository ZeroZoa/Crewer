package NPJ.Crewer.like;

import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/feeds/{feedId}/like")
@RequiredArgsConstructor
public class LikeFeedController {

    private final LikeFeedService likeFeedService;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Long> toggleLike(@PathVariable Long feedId, @AuthenticationPrincipal Member liker) {
        long likeCount = likeFeedService.toggleLike(feedId, liker);
        return ResponseEntity.ok(likeCount);
    }

    @GetMapping("/count")
    public ResponseEntity<Long> countLikes(@PathVariable Long feedId) {
        long likeCount = likeFeedService.countLikes(feedId);
        return ResponseEntity.ok(likeCount);
    }

    @GetMapping("/status")
    public ResponseEntity<Boolean> isLikedByUser(@PathVariable Long feedId, @AuthenticationPrincipal Member liker) {
        if (liker == null) {
            return ResponseEntity.ok(false); //liker가 null이면 false 반환
        }
        boolean isLiked = likeFeedService.isLikedByUser(feedId, liker);
        return ResponseEntity.ok(isLiked);
    }
}
