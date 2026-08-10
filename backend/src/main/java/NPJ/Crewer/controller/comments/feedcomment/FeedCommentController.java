package NPJ.Crewer.controller.comments.feedcomment;

import NPJ.Crewer.service.comments.feedcomment.FeedCommentService;

import NPJ.Crewer.dto.comments.feedcomment.FeedCommentCreateDTO;
import NPJ.Crewer.dto.comments.feedcomment.FeedCommentResponseDTO;
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

    @DeleteMapping("/{commentId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> deleteComment(@PathVariable("feedId") Long feedId,
                                               @PathVariable("commentId") Long commentId,
                                               @AuthenticationPrincipal(expression = "id") Long memberId) {
        feedCommentService.deleteComment(commentId, memberId);
        return ResponseEntity.noContent().build();
    }
}
