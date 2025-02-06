package NPJ.Crewer.config;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Collections;
import java.util.Date;
import java.util.List;

@Component
public class JwtTokenProvider {

    private final String SECRET_KEY = "S3NkNnlYakBMbV85MCFBZ0g3dDVWUXpWYyRScFcW4JllOM0JrOE9qMlQ"; // ✅ 비밀 키
    private final long EXPIRATION_TIME = 86400000; // ✅ 24시간

    private final Key key = Keys.hmacShaKeyFor(SECRET_KEY.getBytes(StandardCharsets.UTF_8));

    // JWT 생성 (username + role 포함)
    public String createToken(String username, String role) {
        return Jwts.builder()
                .setSubject(username)
                .claim("role", role) // ✅ 역할 추가
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME))
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    // JWT 검증
    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
            return true;
        } catch (JwtException e) {
            return false;
        }
    }

    // JWT에서 사용자 정보 가져오기
    public String getUsernameFromToken(String token) {
        Claims claims = Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token)
                .getBody();

        return claims.getSubject();
    }

    // JWT에서 역할(Role) 가져오기
    public String getRoleFromToken(String token) {
        Claims claims = Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token)
                .getBody();

        return claims.get("role", String.class);
    }

    // ✅ JWT에서 사용자 정보(UserDetails) 가져오기 (권한 포함)
    public UserDetails getUserDetailsFromToken(String token) {
        String username = getUsernameFromToken(token);
        String role = getRoleFromToken(token);

        // 🔥 Spring Security의 권한 리스트 포함
        List<GrantedAuthority> authorities = Collections.singletonList(new SimpleGrantedAuthority(role));

        return new User(username, "", authorities);
    }
}