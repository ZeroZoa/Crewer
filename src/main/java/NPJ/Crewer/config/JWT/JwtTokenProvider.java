package NPJ.Crewer.config.JWT;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Date;

@Component
@RequiredArgsConstructor
public class JwtTokenProvider {

    @Value("${jwt.secret}")  // application.properties에서 불러옴
    private String SECRET_KEY;

    private final MemberRepository memberRepository; //Member 엔티티 조회를 위한 Repository 추가

    private final long EXPIRATION_TIME = 10000000;

    private Key key;

    @PostConstruct
    public void init() {
//        if (SECRET_KEY == null || SECRET_KEY.isEmpty()) {
//            throw new IllegalStateException("JWT_SECRET_KEY가 설정되지 않았습니다!");
//        }
//        this.key = Keys.hmacShaKeyFor(SECRET_KEY.getBytes(StandardCharsets.UTF_8));
        byte[] keyBytes = SECRET_KEY.getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length < 32) {
            throw new IllegalArgumentException("JWT 비밀 키는 256비트 이상이어야 합니다.");
        }
        this.key = Keys.hmacShaKeyFor(keyBytes);
    }

    //JWT 생성
    public String createToken(String username, String role) {
        return Jwts.builder()
                .setSubject(username)
                .claim("role", role) // 역할 포함
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME))
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    //JWT 검증
    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
            return true;
        } catch (JwtException e) {
            return false;
        }
    }

    // WT에서 username(이메일) 가져오기
    public String getUsernameFromToken(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token)
                .getBody()
                .getSubject();
    }


    //JWT에서 Member 엔티티 가져오기
    public Member getMemberFromToken(String token) {
        String username = getUsernameFromToken(token);
        return memberRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("사용자 정보를 찾을 수 없습니다."));
    }

    // JwtTokenProvider 클래스에 아래 메서드 추가
    public Long getMemberIdFromToken(String token) {
        String email = Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token)
                .getBody()
                .getSubject();

        // email을 이용해서 memberRepository에서 memberId를 찾아 리턴해야 합니다.
        return memberRepository.findByUsername(email)
                .map(Member::getId)
                .orElseThrow(() -> new UsernameNotFoundException("해당 이메일의 사용자가 없습니다."));
    }

}