package NPJ.Crewer.controller.likes.likefeed;

import NPJ.Crewer.service.likes.likefeed.LikeFeedService;

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
}
