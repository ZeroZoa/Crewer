package NPJ.Crewer.member;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;


public interface MemberRepository extends JpaRepository<Member, Long> {

    //username(로그인 아이디)를 통해 회원 찾기
    Optional<Member> findByUsername(String username);

    //nickname을 통해 회원 찾기
    Optional<Member> findByNickname(String nickname);

    //nickname 중복 확인
    boolean existsByNickname(String nickname);

}
