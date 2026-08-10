package NPJ.Crewer.controller.member;

import NPJ.Crewer.service.member.MemberService;


import NPJ.Crewer.dto.member.MemberRegisterDTO;
import NPJ.Crewer.dto.member.MemberLoginDTO;
import NPJ.Crewer.dto.member.MemberUsernameDTO;
import NPJ.Crewer.dto.member.ResetPasswordDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RequiredArgsConstructor
@RestController
@RequestMapping("/members")
public class MemberController {

    private final MemberService memberService;

    //회원가입을 위한 이메일 확인 메일 발송
    @PostMapping("/send-verification-code")
    public ResponseEntity<String> sendVerificationCode(@RequestParam("email") String email) {
        System.out.println("시작");
        memberService.sendVerificationCode(email);
        return ResponseEntity.ok("인증 코드가 이메일로 발송되었습니다.");
    }

    //회원가입을 위한 이메일 확인 메일 확인
    @PostMapping("/verify-code")
    public ResponseEntity<?> verifyCode(@RequestParam("email") String email,
                                             @RequestParam("code") String code) {
        String verifiedToken = memberService.verifyCode(email, code);

        Map<String, String> response = new HashMap<>();
        response.put("verifiedToken", verifiedToken);
        return ResponseEntity.ok(response);
    }

    // 회원가입 요청 처리
    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> registerMember(@Valid @RequestBody MemberRegisterDTO memberRegisterDTO) {
        memberService.registerMember(memberRegisterDTO);

        Map<String, Object> responseBody = new HashMap<>();
        responseBody.put("success", true);
        responseBody.put("message", "회원가입이 완료되었습니다.");

        return ResponseEntity.ok(responseBody);
    }

    // 로그인 요청 처리
    @PostMapping("/login")
    public ResponseEntity<String> login(@Valid @RequestBody MemberLoginDTO memberLoginDTO) {
        String token = memberService.login(memberLoginDTO);
        return ResponseEntity.ok(token); // 클라이언트에 JWT 토큰 반환
    }

    // 이메일(아이디) 존재 검증
    @PostMapping("/check-username")
    public ResponseEntity<String> checkUsername(@Valid @RequestBody MemberUsernameDTO memberUsernameDTO) {
        boolean exists = memberService.existsByUsername(memberUsernameDTO.getUsername());
        if (exists) {
            return ResponseEntity.ok("exists");
        } else {
            return ResponseEntity.status(404).body("not_found");
        }
    }

    // 비밀번호 재설정
    @PostMapping("/reset-password")
    public ResponseEntity<String> resetPassword(@Valid @RequestBody ResetPasswordDTO resetPasswordDTO) {
        memberService.resetPassword(resetPasswordDTO.getUsername(), resetPasswordDTO.getNewPassword());
        return ResponseEntity.ok("password_reset_success");
    }

    //로그아웃 요청 처리
    @PostMapping("/logout")
    public ResponseEntity<String> logout(@AuthenticationPrincipal(expression = "id") Long memberId,
                                          @RequestHeader("Authorization") String authHeader){
        String token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;
        memberService.logout(memberId, token);
        return ResponseEntity.ok("로그아웃이 완료되었습니다.");
    }
}
