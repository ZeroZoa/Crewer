package NPJ.Crewer.comment;

import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/feeds/{feedId}/comments")
@RequiredArgsConstructor
public class CommentController {
    private final CommentService commentService;
    private final MemberService memberService;

    //댓글 작성
    @PostMapping
    public ResponseEntity<?> createComment(@Valid @RequestBody CommentDTO commentDTO, @PathVariable Long feedId, BindingResult bindingResult) {
        //입력값 검증
        if (bindingResult.hasErrors()) {
            return ResponseEntity.badRequest().body("입력값이 올바르지 않습니다.");
        }

        //로그인 여부 확인
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인이 필요합니다.");
        }

        //현재 로그인된 사용자 가져오기
        String username = authentication.getName();
        Optional<Member> optionalMember = Optional.ofNullable(memberService.getMember(username));

        //회원 정보가 없으면 403 Forbidden 반환
        if (optionalMember.isEmpty()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("사용자 정보를 찾을 수 없습니다.");
        }

        Member member = optionalMember.get();
        Comment comment = commentService.create(feedId, commentDTO.getContent(), member);


        return ResponseEntity.ok(comment);
    }


    //특정 피드의 댓글 조회
    @GetMapping
    public ResponseEntity<List<Comment>> getComments(@PathVariable Long feedId) {
        List<Comment> comments = commentService.getCommentsByFeed(feedId);
        return ResponseEntity.ok(comments);
    }

    //댓글 삭제
    @DeleteMapping("/{commentId}")
    public ResponseEntity<Void> deleteComment(
            @PathVariable Long commentId,
            @AuthenticationPrincipal String username, // 현재 로그인한 사용자
            @PathVariable String feedId) {
        commentService.delete(commentId, username);
        return ResponseEntity.noContent().build();
    }
}