package NPJ.Crewer.domain.profile;

import NPJ.Crewer.domain.member.Member;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 간소화된 프로필 DTO (팔로워/팔로잉 목록용)
 * N+1 문제를 방지하기 위해 팔로워/팔로잉 수를 제외한 기본 정보만 포함한다.
 */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SimpleProfileDTO {
    private String username;
    private String nickname;
    private String avatarUrl;
    private double temperature;
    private boolean isFollowingByMe;

    /**
     * Member 엔티티로부터 SimpleProfileDTO를 생성한다.
     * isFollowingByMe는 호출부에서 벌크로 미리 계산해서 넘겨야 한다 (N+1 방지).
     */
    public static SimpleProfileDTO from(Member member, boolean isFollowingByMe) {
        return SimpleProfileDTO.builder()
                .username(member.getUsername())
                .nickname(member.getNickname())
                .avatarUrl(member.getProfile().getAvatarUrl())
                .temperature(member.getProfile().getTemperature())
                .isFollowingByMe(isFollowingByMe)
                .build();
    }
}

