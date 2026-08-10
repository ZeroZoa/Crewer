package NPJ.Crewer.controller.likes.likegroupfeed;

import NPJ.Crewer.service.likes.likegroupfeed.LikeGroupFeedService;

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
    public ResponseEntity<Long> toggleLike(@PathVariable("groupFeedId") Long groupFeedId,
                                           @AuthenticationPrincipal(expression = "id") Long memberId) {
        long likeCount = likeGroupFeedService.toggleLike(groupFeedId, memberId);
        return ResponseEntity.ok(likeCount);
    }
}
