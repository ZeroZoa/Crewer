package NPJ.Crewer.global.util;

import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;

@NoArgsConstructor(access = AccessLevel.PRIVATE)
public final class MemberUtil {

    private static final String MEMBER_NOT_FOUND_MESSAGE = "회원 정보가 없습니다.";

    /**
     * ID로 회원을 조회하고, 없으면 예외를 발생시킨다.
     */
    public static Member getMemberOrThrow(MemberRepository memberRepository, Long memberId) {
        return memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException(MEMBER_NOT_FOUND_MESSAGE));
    }

    /**
     * 사용자명으로 회원을 조회하고, 없으면 예외를 발생시킨다.
     */
    public static Member getMemberByUsernameOrThrow(MemberRepository memberRepository, String username) {
        return memberRepository.findByUsername(username)
                .orElseThrow(() -> new EntityNotFoundException(MEMBER_NOT_FOUND_MESSAGE));
    }
}

