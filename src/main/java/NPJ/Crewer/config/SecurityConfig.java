package NPJ.Crewer.config;

import NPJ.Crewer.config.JWT.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable) // CSRF 비활성화
                .cors(cors -> cors.configurationSource(corsConfigurationSource())) // CORS 설정 적용
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)) // 세션 사용 안함 (JWT)
                .authorizeHttpRequests(auth -> auth
                        //인증 없이 접근 가능한 엔드포인트
                        .requestMatchers("/members/register", "/members/login").permitAll() // 회원가입, 로그인 공개
                        .requestMatchers("/crewerimages/**").permitAll()

                        //일반 피드 (Feed) 관련 요청
                        .requestMatchers(HttpMethod.GET, "/feeds", "/feeds/**").permitAll() // 피드 조회 공개
                        .requestMatchers(HttpMethod.GET, "/feeds/{id}/comments").permitAll() // 댓글 조회 공개
                        .requestMatchers(HttpMethod.GET, "/feeds/{id}/like/count").permitAll() // 좋아요 수 조회 공개

                        //그룹 피드 (GroupFeed) 관련 요청
                        .requestMatchers(HttpMethod.GET, "/groupfeeds", "/groupfeeds/**").permitAll() // 그룹 피드 조회 공개
                        .requestMatchers(HttpMethod.GET, "/groupfeeds/{id}/comments").permitAll() // 그룹 피드 댓글 조회 공개
                        .requestMatchers(HttpMethod.GET, "/groupfeeds/{id}/like/count").permitAll() // 그룹 피드 좋아요 수 조회 공개

                        //기타 공개 엔드포인트
                        .requestMatchers(HttpMethod.GET, "/api/config/google-maps-key").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/config/google-maps-map-id").permitAll()
                        
                        // Region API 공개 엔드포인트 (테스트용)
                        .requestMatchers(HttpMethod.GET, "/api/regions/provinces").permitAll() // 시/도 목록 조회 공개
                        .requestMatchers(HttpMethod.GET, "/api/regions/*/cities").permitAll() // 시/군/구 목록 조회 공개
                        .requestMatchers(HttpMethod.GET, "/api/regions/*/cities/*/districts/search").permitAll() // 행정동 검색 공개
                        .requestMatchers(HttpMethod.GET, "/api/regions/*/districts").permitAll() // 시/도별 모든 행정동 조회 공개
                        .requestMatchers(HttpMethod.GET, "/api/regions/*/districts/search").permitAll() // 시/도별 행정동 검색 공개
                        .requestMatchers(HttpMethod.GET, "/api/regions/districts/*").permitAll() // 행정동 상세 조회 공개
                        .requestMatchers(HttpMethod.GET, "/api/regions/*/geojson").permitAll() // GeoJSON 데이터 조회 공개

                        //인증이 필요한 일반 피드 (Feed) 관련 요청
                        .requestMatchers(HttpMethod.POST, "/feeds/create").authenticated() // 피드 작성 인증 필요
                        .requestMatchers(HttpMethod.PUT, "/feeds/{id}/edit").authenticated() // 피드 수정 인증 필요
                        .requestMatchers(HttpMethod.DELETE, "/feeds/{id}").authenticated() // 피드 삭제 인증 필요
                        .requestMatchers(HttpMethod.POST, "/feeds/{id}/comments").authenticated() // 댓글 작성 인증 필요
                        .requestMatchers(HttpMethod.DELETE, "/feeds/{id}/comments/{commentId}").authenticated() // 특정 댓글 삭제 인증 필요
                        .requestMatchers(HttpMethod.GET, "/feeds/{id}/like/status").authenticated() // 좋아요 상태 조회 인증 필요
                        .requestMatchers(HttpMethod.POST, "/feeds/{id}/like").authenticated() // 좋아요 토글 인증 필요

                        //인증이 필요한 그룹 피드 (GroupFeed) 관련 요청
                        .requestMatchers(HttpMethod.POST, "/groupfeeds/create").authenticated() // 그룹 피드 작성 인증 필요
                        .requestMatchers(HttpMethod.PUT, "/groupfeeds/{id}/edit").authenticated() // 그룹 피드 수정 인증 필요
                        .requestMatchers(HttpMethod.DELETE, "/groupfeeds/{id}").authenticated() // 그룹 피드 삭제 인증 필요
                        .requestMatchers(HttpMethod.POST, "/groupfeeds/{id}/comments").authenticated() // 그룹 피드 댓글 작성 인증 필요
                        .requestMatchers(HttpMethod.DELETE, "/groupfeeds/{id}/comments/{commentId}").authenticated() // 특정 그룹 피드 댓글 삭제 인증 필요
                        .requestMatchers(HttpMethod.GET, "/groupfeeds/{id}/like/status").authenticated() // 그룹 피드 좋아요 상태 조회 인증 필요
                        .requestMatchers(HttpMethod.POST, "/groupfeeds/{id}/like").authenticated() // 그룹 피드 좋아요 토글 인증 필요
                        .requestMatchers(HttpMethod.POST, "/groupfeeds/{id}/participants").authenticated() // 그룹 피드 참가/탈퇴 인증 필요

                        //인증이 필요한 달리기 랭킹, 기록 (Ranking) 관련 요청
                        .requestMatchers(HttpMethod.POST, "/running/create").authenticated() // 달리기 기록 저장 인증 필요
                        .requestMatchers(HttpMethod.GET, "/running").authenticated() // 달리기 기록 조회 인증 필요
                        .requestMatchers(HttpMethod.GET, "/running/ranking").authenticated() // 랭킹 조회 인증 필요

                        //인증이 필요한 프로필 관련 요청
                        .requestMatchers(HttpMethod.GET, "/me").authenticated() //프로필 조회 인증 필요

                        //인증이 필요한 채팅 관련 요청(전부 요청 필요)
                        .requestMatchers(HttpMethod.POST, "/groupfeeds/{id}/join-chat").authenticated() // 그룹 피드-채팅 연계 인증 필요
                        .requestMatchers(HttpMethod.POST, "/directChat/**").authenticated()//1대1채팅방 생성및 참가 인증 필요
                        .requestMatchers(HttpMethod.GET, "/chat").authenticated() // 채팅방 리스트 불러오기 인증 필요
                        .requestMatchers(HttpMethod.GET, "/chat/{id}").authenticated() // 채팅방 대화 불러오기 인증 필요
                        .requestMatchers(HttpMethod.POST, "/chat/{id}/send").authenticated() // 그룹 피드-채팅 연계 인증 필요
                        .requestMatchers("/chat/**").authenticated() // 채팅 관련 API 인증 필요
                        .requestMatchers("/ws/**").permitAll()

                        //기타 인증이 필요한 요청
                        .requestMatchers("/profile/**").authenticated() // 프로필 관련 API 인증 필요
                        .anyRequest().authenticated() // 그 외 모든 요청은 인증 필요
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class); // JWT 필터 추가

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authenticationConfiguration) throws Exception {
        return authenticationConfiguration.getAuthenticationManager();
    }

    //CORS 설정 (React 프론트엔드와 통신 가능하도록 설정)
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(List.of("http://localhost:3000")); // React 개발 서버 허용
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        configuration.setExposedHeaders(List.of("Authorization")); //프론트에서 JWT 토큰 접근 허용
        configuration.setAllowCredentials(true); //쿠키 기반 인증을 위한 설정

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}