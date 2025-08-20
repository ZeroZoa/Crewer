package NPJ.Crewer.member;

import NPJ.Crewer.config.JWT.JwtTokenProvider;
import NPJ.Crewer.member.dto.MemberRegisterDTO;
import NPJ.Crewer.member.dto.MemberLoginDTO;
import NPJ.Crewer.profile.Profile;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.NoSuchElementException;

@Service
@RequiredArgsConstructor
public class MemberService {
    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    //회원가입 로직
    public void registerMember(MemberRegisterDTO memberRegisterDTO){
        // 이메일 중복 검사
        if (memberRepository.findByUsername(memberRegisterDTO.getUsername()).isPresent()) {
            throw new IllegalArgumentException("이미 사용 중인 이메일입니다.");
        }

        // 닉네임 중복 검사
        if (memberRepository.findByNickname(memberRegisterDTO.getNickname()).isPresent()) {
            throw new IllegalArgumentException("이미 사용 중인 닉네임입니다.");
        }

        // 비밀번호 확인 검사(동일한지)
        if (!memberRegisterDTO.getPassword1().equals(memberRegisterDTO.getPassword2())) {
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

        //위 이메일, 닉네임, 비밀번호에 대한 검사가 끝나면 회원 엔티티를 생성
        // 회원 엔티티 생성
        Member member = new Member(
                memberRegisterDTO.getUsername(),
                passwordEncoder.encode(memberRegisterDTO.getPassword1()),
                memberRegisterDTO.getNickname(),
                MemberRole.USER
        );

        //빌더를 통해 생성 후 데이터베이스에 저장
        memberRepository.save(member);
    }

    //로그인 로직
    public String login(MemberLoginDTO memberLoginDTO) {
        // 이메일로 사용자 검색
        Member member = memberRepository.findByUsername(memberLoginDTO.getUsername())
                .orElseThrow(() -> new NoSuchElementException("사용자가 존재하지 않습니다."));

        // 비밀번호 검증
        if (!passwordEncoder.matches(memberLoginDTO.getPassword(), member.getPassword())) {
            throw new IllegalArgumentException("비밀번호가 올바르지 않습니다.");
        }

        // JWT 생성
        return jwtTokenProvider.createToken(member.getUsername(), member.getRole().getValue());
    }

    //로그아웃 로직
    public void logout(Long memberId) {
        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));



    }

}
