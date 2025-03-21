package NPJ.Crewer.comment.groupFeedComment;

import NPJ.Crewer.comment.feedComment.dto.GroupFeedCommentResponseDTO;
import NPJ.Crewer.comment.groupFeedComment.dto.GroupFeedCommentCreateDTO;
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
@RequestMapping("/groupfeeds/{groupFeedId}/comments")
public class GroupFeedCommentController {
    private final GroupFeedCommentService groupFeedCommentService;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<GroupFeedCommentResponseDTO> createComment(@PathVariable Long groupFeedId,
                                                                     @AuthenticationPrincipal Member member,
                                                                     @Valid @RequestBody GroupFeedCommentCreateDTO groupFeedCommentCreateDTO) {
        GroupFeedCommentResponseDTO feedCommentResponseDTO = groupFeedCommentService.createComment(groupFeedId, groupFeedCommentCreateDTO, member);
        return ResponseEntity.status(HttpStatus.CREATED).body(feedCommentResponseDTO);
    }

    @GetMapping
    public ResponseEntity<List<GroupFeedCommentResponseDTO>> getComments(@PathVariable Long groupFeedId) {
        List<GroupFeedCommentResponseDTO> comments = groupFeedCommentService.getCommentsByGroupFeed(groupFeedId);
        return ResponseEntity.ok(comments);
    }
}
