package NPJ.Crewer.profile;

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
}