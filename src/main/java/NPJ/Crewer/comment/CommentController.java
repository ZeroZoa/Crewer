package NPJ.Crewer.comment;

import NPJ.Crewer.comment.dto.CommentCreateDTO;
import NPJ.Crewer.comment.dto.CommentResponseDTO;
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
public class CommentController {
    private final CommentService commentService;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<CommentResponseDTO> createComment(@PathVariable Long feedId,
                                                            @AuthenticationPrincipal Member member,
                                                            @Valid @RequestBody CommentCreateDTO commentCreateDTO) {
        CommentResponseDTO commentResponseDTO = commentService.createComment(feedId, commentCreateDTO, member);
        return ResponseEntity.status(HttpStatus.CREATED).body(commentResponseDTO);
    }

    @GetMapping
    public ResponseEntity<List<CommentResponseDTO>> getComments(@PathVariable Long feedId) {
        List<CommentResponseDTO> comments = commentService.getCommentsByFeed(feedId);
        return ResponseEntity.ok(comments);
    }
}
