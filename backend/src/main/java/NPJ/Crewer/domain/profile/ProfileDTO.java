package NPJ.Crewer.domain.profile;

import NPJ.Crewer.domain.member.Member;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.util.List;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProfileDTO {
    private String username;
    private String nickname;
    private String avatarUrl;
    private double temperature;
    private List<String> interests;
    private int followersCount;
    private int followingCount;

    /**
     * Member 엔티티로부터 ProfileDTO를 생성
     */
    public static ProfileDTO from(Member member, long followersCount, long followingCount) {
        return ProfileDTO.builder()
                .username(member.getUsername())
                .nickname(member.getNickname())
                .avatarUrl(member.getProfile().getAvatarUrl())
                .temperature(member.getProfile().getTemperature())
                .interests(member.getProfile().getInterests())
                .followersCount((int) followersCount)
                .followingCount((int) followingCount)
                .build();
    }
}

