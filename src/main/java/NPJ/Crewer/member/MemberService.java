package NPJ.Crewer.member;

import NPJ.Crewer.config.JWT.JwtTokenProvider;
import NPJ.Crewer.email.EmailService;
import NPJ.Crewer.member.dto.MemberRegisterDTO;
import NPJ.Crewer.member.dto.MemberLoginDTO;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.NoSuchElementException;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class MemberService {
    private final MemberRepository memberRepository;
    private final EmailService emailService;
    private final StringRedisTemplate redisTemplate;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;


    private static final String EMAIL_VERIFICATION_KEY_PREFIX = "email-verification:"; //인증 받을 메일
    private static final String VERIFIED_EMAIL_KEY_PREFIX = "verified-email:"; //인증 완료 메일
    private static final long EMAIL_VERIFICATION_TIMEOUT_MINUTES = 5; //인증 코드 유효 시간
    private static final long VERIFIED_STATE_TIMEOUT_MINUTES = 5; // 인증 완료 유효 시간

    //인증코드 이메일 발송
    @Transactional
    public void sendVerificationCode(String email){

        if (memberRepository.findByUsername(email).isPresent()) {
            throw new IllegalArgumentException("이미 가입된 이메일입니다.");
        }

        String verificationCode = createVerificationCode();
        String redisKey = EMAIL_VERIFICATION_KEY_PREFIX + email;

        redisTemplate.opsForValue().set(
                redisKey,
                verificationCode,
                EMAIL_VERIFICATION_TIMEOUT_MINUTES,
                TimeUnit.MINUTES
        );

        emailService.sendVerificationEmail(email, verificationCode);
    }

    //인증코드 확인
    public String verifyCode(String email, String userSubmittedCode){

        String redisKey = EMAIL_VERIFICATION_KEY_PREFIX + email;
        String storedCode = redisTemplate.opsForValue().get(redisKey);

        if (storedCode == null || !storedCode.equals(userSubmittedCode)) {
            return null; //예외 에러메세지 보내도록 수정
        }

        redisTemplate.delete(redisKey); // 사용된 인증 코드는 삭제

        //인증완료 토큰 생성
        String verifiedToken = UUID.randomUUID().toString();
        String verifiedRedisKey = VERIFIED_EMAIL_KEY_PREFIX + verifiedToken;
        redisTemplate.opsForValue().set(
                verifiedRedisKey,
                email,
                VERIFIED_STATE_TIMEOUT_MINUTES,
                TimeUnit.MINUTES);

        return verifiedToken;
    }

    //인증코드 생성
    private String createVerificationCode(){
        SecureRandom secureRandom = new SecureRandom();
        int randomNumber = 100000 + secureRandom.nextInt(900000);
        return String.valueOf(randomNumber);
    }

    @Transactional
    public void registerMember(MemberRegisterDTO memberRegisterDTO){

        String verifiedRedisKey = VERIFIED_EMAIL_KEY_PREFIX + memberRegisterDTO.getVerifiedToken();
        String verifiedEmail = redisTemplate.opsForValue().get(verifiedRedisKey);

        if (verifiedEmail == null || !verifiedEmail.equals(memberRegisterDTO.getUsername())) {
            throw new IllegalArgumentException("유효하지 않은 이메일 인증 토큰입니다.");
        }
        // 사용자 정보 유효성 검사 로직
        if (memberRepository.findByUsername(memberRegisterDTO.getUsername()).isPresent()) {
            throw new IllegalArgumentException("이미 사용 중인 이메일입니다.");
        }
        if (memberRepository.findByNickname(memberRegisterDTO.getNickname()).isPresent()) {
            throw new IllegalArgumentException("이미 사용 중인 닉네임입니다.");
        }
        if (!memberRegisterDTO.getPassword1().equals(memberRegisterDTO.getPassword2())) {
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

        // 인증 코드 및 토근 유효성 검사 로직


        Member member = new Member(
                memberRegisterDTO.getUsername(),
                passwordEncoder.encode(memberRegisterDTO.getPassword1()),
                memberRegisterDTO.getNickname(),
                MemberRole.USER
        );

        member.setEmailVerifiedAt(Instant.now());
        memberRepository.save(member);

        redisTemplate.delete(verifiedRedisKey);
    }


    @Transactional(readOnly = true)
    public String login(MemberLoginDTO memberLoginDTO) {
        Member member = memberRepository.findByUsername(memberLoginDTO.getUsername())
                .orElseThrow(() -> new NoSuchElementException("사용자가 존재하지 않습니다."));

        if (!passwordEncoder.matches(memberLoginDTO.getPassword(), member.getPassword())) {
            throw new IllegalArgumentException("비밀번호가 올바르지 않습니다.");
        }

        // (개선) 로그인 시에도 이메일 인증 여부를 확인하는 것이 더 안전합니다.
        if (member.getEmailVerifiedAt() == null) {
            throw new IllegalStateException("이메일 인증이 완료되지 않은 계정입니다.");
        }

        return jwtTokenProvider.createToken(member.getUsername(), member.getRole().getValue());
    }

    @Transactional(readOnly = true)
    public boolean existsByUsername(String username) {
        return memberRepository.findByUsername(username).isPresent();
    }

    @Transactional
    public void resetPassword(String username, String newPassword) {
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new NoSuchElementException("사용자가 존재하지 않습니다."));
        member.setPassword(passwordEncoder.encode(newPassword));
    }

    @Transactional(readOnly = true)
    public void logout(Long memberId) {
        memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));
    }
}