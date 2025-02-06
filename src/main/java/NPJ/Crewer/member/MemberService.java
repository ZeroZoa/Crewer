package NPJ.Crewer.member;

import NPJ.Crewer.config.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class MemberService {
    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    //회원가입 로직
    public Member createMember(MemberCreateDTO dto) {
        // 이메일 중복 검사
        if (memberRepository.findByUsername(dto.getUsername()).isPresent()) {
            throw new IllegalArgumentException("이미 사용 중인 이메일입니다.");
        }

        // 닉네임 중복 검사
        if (memberRepository.findByNickname(dto.getNickname()).isPresent()) {
            throw new IllegalArgumentException("이미 사용 중인 닉네임입니다.");
        }

        // 비밀번호 확인
        if (!dto.getPassword1().equals(dto.getPassword2())) {
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

        // 회원 엔티티 생성
        Member member = Member.builder()
                .username(dto.getUsername())
                .password(passwordEncoder.encode(dto.getPassword1()))
                .nickname(dto.getNickname())
                .role(MemberRole.USER)
                .build();

        return memberRepository.save(member);
    }

    // 로그인 로직
    public String login(MemberLoginDTO memberLoginDTO) {
        // 이메일로 사용자 검색
        Member member = memberRepository.findByUsername(memberLoginDTO.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("사용자가 존재하지 않습니다."));

        // 비밀번호 검증
        if (!passwordEncoder.matches(memberLoginDTO.getPassword(), member.getPassword())) {
            throw new IllegalArgumentException("비밀번호가 올바르지 않습니다.");
        }

        // JWT 생성
        return jwtTokenProvider.createToken(member.getUsername(), member.getRole().getValue());
    }


    public Member getMember(String username) {
        Optional<Member> member = this.memberRepository.findByUsername(username);
        if (member.isPresent()) {
            return member.get();
        } else {
            throw new IllegalArgumentException("member not found");
        }
    }
}