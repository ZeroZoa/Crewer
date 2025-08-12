package NPJ.Crewer.member;


import NPJ.Crewer.member.dto.MemberRegisterDTO;
import NPJ.Crewer.member.dto.MemberLoginDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/members")
public class MemberController {

    private final MemberService memberService;

    // 회원가입 요청 처리
    @PostMapping("/register")
    public ResponseEntity<String> registerMember(@Valid @RequestBody MemberRegisterDTO memberRegisterDTO) {
        memberService.registerMember(memberRegisterDTO);
        return ResponseEntity.ok("회원가입이 완료되었습니다.");
    }

    // 로그인 요청 처리
    @PostMapping("/login")
    public ResponseEntity<String> login(@RequestBody MemberLoginDTO memberLoginDTO) {
        String token = memberService.login(memberLoginDTO);
        return ResponseEntity.ok(token); // 클라이언트에 JWT 토큰 반환
    }

    //로그아웃 요청 처리
    @PostMapping("/logout")
    public ResponseEntity<String> logout(@AuthenticationPrincipal(expression = "id") Long memberId){

        memberService.logout(memberId);
        return ResponseEntity.ok("로그아웃이 완료되었습니다.");
    }
}
