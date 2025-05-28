package NPJ.Crewer.comment.feedComment;

import NPJ.Crewer.comment.feedComment.dto.FeedCommentCreateDTO;
import NPJ.Crewer.comment.feedComment.dto.FeedCommentResponseDTO;
import NPJ.Crewer.member.Member;
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
    public ResponseEntity<FeedCommentResponseDTO> createComment(@PathVariable Long feedId,
                                                                @AuthenticationPrincipal Member member,
                                                                @Valid @RequestBody FeedCommentCreateDTO feedCommentCreateDTO) {
        FeedCommentResponseDTO feedCommentResponseDTO = feedCommentService.createComment(feedId, feedCommentCreateDTO, member);
        return ResponseEntity.status(HttpStatus.CREATED).body(feedCommentResponseDTO);
    }

    @GetMapping
    public ResponseEntity<List<FeedCommentResponseDTO>> getComments(@PathVariable Long feedId) {
        List<FeedCommentResponseDTO> comments = feedCommentService.getCommentsByFeed(feedId);
        return ResponseEntity.ok(comments);
    }
}
