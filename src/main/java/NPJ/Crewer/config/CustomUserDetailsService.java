package NPJ.Crewer.config;

import lombok.RequiredArgsConstructor;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final MemberRepository memberRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // 데이터베이스에서 사용자 정보 조회
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("사용자를 찾을 수 없습니다: " + username));

        // 사용자 역할(Role)을 Security의 GrantedAuthority로 변환
        List<GrantedAuthority> authorities = Collections.singletonList(
                new SimpleGrantedAuthority(member.getRole().getValue()) // "ROLE_USER" or "ROLE_ADMIN"
        );

        // UserDetails 반환 (Spring Security에서 사용)
        return new User(member.getUsername(), member.getPassword(), authorities);
    }
}