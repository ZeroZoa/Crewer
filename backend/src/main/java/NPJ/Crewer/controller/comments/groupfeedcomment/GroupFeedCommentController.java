package NPJ.Crewer.controller.comments.groupfeedcomment;

import NPJ.Crewer.service.comments.groupfeedcomment.GroupFeedCommentService;

import NPJ.Crewer.dto.comments.feedcomment.FeedCommentResponseDTO;
import NPJ.Crewer.dto.comments.groupfeedcomment.GroupFeedCommentCreateDTO;
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
@RequestMapping("/groupfeeds/{groupFeedId}/comments")
public class GroupFeedCommentController {
    private final GroupFeedCommentService groupFeedCommentService;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FeedCommentResponseDTO> createComment(@PathVariable("groupFeedId") Long groupFeedId,
                                                                @AuthenticationPrincipal(expression = "id") Long memberId,
                                                                @Valid @RequestBody GroupFeedCommentCreateDTO groupFeedCommentCreateDTO) {
        FeedCommentResponseDTO feedCommentResponseDTO = groupFeedCommentService.createComment(groupFeedId, groupFeedCommentCreateDTO, memberId);
        return ResponseEntity.status(HttpStatus.CREATED).body(feedCommentResponseDTO);
    }

    @GetMapping
    public ResponseEntity<List<FeedCommentResponseDTO>> getComments(@PathVariable("groupFeedId") Long groupFeedId) {
        List<FeedCommentResponseDTO> comments = groupFeedCommentService.getCommentsByGroupFeed(groupFeedId);
        return ResponseEntity.ok(comments);
    }

    @DeleteMapping("/{commentId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> deleteComment(@PathVariable("groupFeedId") Long groupFeedId,
                                               @PathVariable("commentId") Long commentId,
                                               @AuthenticationPrincipal(expression = "id") Long memberId) {
        groupFeedCommentService.deleteComment(commentId, memberId);
        return ResponseEntity.noContent().build();
    }
}
