package NPJ.Crewer.member;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RequiredArgsConstructor
@RestController
@RequestMapping("/members")
public class MemberController {

    private final MemberService memberService;

    // 회원가입 요청 처리
    @PostMapping("/register")
    public ResponseEntity<?> registerMember(@Valid @RequestBody MemberCreateDTO memberCreateDTO) {
        // 비밀번호 확인
        if (!memberCreateDTO.getPassword1().equals(memberCreateDTO.getPassword2())) {
            return ResponseEntity.badRequest().body("비밀번호가 일치하지 않습니다.");
        }

        try {
            // 회원 생성 서비스 호출
            memberService.createMember(memberCreateDTO);
        } catch (DataIntegrityViolationException e) {
            // 데이터 무결성 제약 조건 위반 처리
            if (e.getMessage().contains("nickname")) {
                return ResponseEntity.badRequest().body("닉네임이 이미 존재합니다.");
            }
            return ResponseEntity.badRequest().body("이미 등록된 이메일입니다.");
        } catch (Exception e) {
            // 기타 예외 처리
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("회원가입 중 오류가 발생했습니다.");
        }

        // 성공 응답
        return ResponseEntity.ok("회원가입이 완료되었습니다.");
    }

    // 로그인 API
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody MemberLoginDTO memberLoginDTO) {
        try {
            String token = memberService.login(memberLoginDTO); // JWT 발급
            return ResponseEntity.ok(token); // 클라이언트에 토큰 반환
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}