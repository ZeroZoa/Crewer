package NPJ.Crewer.like.likeFeed;

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
    public ResponseEntity<Long> toggleLike(@PathVariable("feedId") Long feedId,
                                           @AuthenticationPrincipal(expression = "id") Long memberId) {
        long likeCount = likeFeedService.toggleLike(feedId, memberId);
        return ResponseEntity.ok(likeCount);
    }

    @GetMapping("/count")
    public ResponseEntity<Long> countLikes(@PathVariable("feedId") Long feedId) {
        long likeCount = likeFeedService.countLikes(feedId);
        return ResponseEntity.ok(likeCount);
    }

    @GetMapping("/status")
    public ResponseEntity<Boolean> isLikedByUser(@PathVariable("feedId") Long feedId,
                                                 @AuthenticationPrincipal(expression = "id") Long memberId) {

        boolean isLiked = likeFeedService.isLikedByUser(feedId, memberId);
        return ResponseEntity.ok(isLiked);
    }
}
