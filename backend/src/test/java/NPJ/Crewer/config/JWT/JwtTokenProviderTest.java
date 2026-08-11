package NPJ.Crewer.config.JWT;

import NPJ.Crewer.repository.member.MemberRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;

@ExtendWith(MockitoExtension.class)
class JwtTokenProviderTest {

    @Mock
    private MemberRepository memberRepository;

    private JwtTokenProvider jwtTokenProvider;

    @BeforeEach
    void setUp() {
        jwtTokenProvider = new JwtTokenProvider(memberRepository);
        // 테스트용 256비트 이상 시크릿 키 주입 (application.properties의 ${jwt.secret} 역할)
        ReflectionTestUtils.setField(jwtTokenProvider, "SECRET_KEY", "test-jwt-secret-key-for-unit-test-must-be-32-bytes-plus");
        jwtTokenProvider.init();
    }

    @Test
    void 발급한_토큰은_유효하다면() {
        String token = jwtTokenProvider.createToken("user1", "ROLE_USER");

        assertThat(jwtTokenProvider.validateToken(token)).isTrue();
        assertThat(jwtTokenProvider.getUsernameFromToken(token)).isEqualTo("user1");
    }

    @Test
    void 위조된_토큰은_유효하지_않다면() {
        String token = jwtTokenProvider.createToken("user1", "ROLE_USER");
        String tampered = token.substring(0, token.length() - 1) + (token.endsWith("a") ? "b" : "a");

        assertThat(jwtTokenProvider.validateToken(tampered)).isFalse();
    }

    @Test
    void 발급_직후_토큰의_남은_유효시간은_72시간에_가깝다면() {
        String token = jwtTokenProvider.createToken("user1", "ROLE_USER");

        long remaining = jwtTokenProvider.getRemainingExpiration(token);
        long seventyTwoHoursMs = 1000L * 60 * 60 * 72;

        assertThat(remaining).isPositive();
        assertThat(remaining).isLessThanOrEqualTo(seventyTwoHoursMs);
        assertThat(remaining).isGreaterThan(seventyTwoHoursMs - 5000); // 실행 시간 오차 허용
    }
}
