package NPJ.Crewer.comments.feedcomment;

import NPJ.Crewer.comments.feedcomment.dto.FeedCommentCreateDTO;
import NPJ.Crewer.comments.feedcomment.dto.FeedCommentResponseDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/feeds/{feedId}/comments")
public class FeedCommentController {
    private final FeedCommentService feedCommentService;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FeedCommentResponseDTO> createComment(@PathVariable("feedId") Long feedId,
                                                                @AuthenticationPrincipal(expression = "id") Long memberId,
                                                                @Valid @RequestBody FeedCommentCreateDTO feedCommentCreateDTO) {
        FeedCommentResponseDTO feedCommentResponseDTO = feedCommentService.createComment(feedId, feedCommentCreateDTO, memberId);
        return ResponseEntity.status(HttpStatus.CREATED).body(feedCommentResponseDTO);
    }

    @GetMapping
    public ResponseEntity<List<FeedCommentResponseDTO>> getComments(@PathVariable("feedId") Long feedId) {
        List<FeedCommentResponseDTO> comments = feedCommentService.getCommentsByFeed(feedId);
        return ResponseEntity.ok(comments);
    }
}
