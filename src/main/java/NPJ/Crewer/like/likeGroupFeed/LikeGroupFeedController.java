package NPJ.Crewer.like.likeGroupFeed;

import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/groupfeeds/{groupFeedId}/like")
@RequiredArgsConstructor
public class LikeGroupFeedController {

    private final LikeGroupFeedService likeGroupFeedService;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Long> toggleLike(@PathVariable Long groupFeedId,
                                           @AuthenticationPrincipal(expression = "id") Long memberId) {
        long likeCount = likeGroupFeedService.toggleLike(groupFeedId, memberId);
        return ResponseEntity.ok(likeCount);
    }

    @GetMapping("/count")
    public ResponseEntity<Long> countLikes(@PathVariable Long groupFeedId) {
        long likeCount = likeGroupFeedService.countLikes(groupFeedId);
        return ResponseEntity.ok(likeCount);
    }

    @GetMapping("/status")
    public ResponseEntity<Boolean> isLikedByUser(@PathVariable Long groupFeedId,
                                                 @AuthenticationPrincipal(expression = "id") Long memberId) {

        boolean isLiked = likeGroupFeedService.isLikedByUser(groupFeedId, memberId);
        return ResponseEntity.ok(isLiked);
    }
}
