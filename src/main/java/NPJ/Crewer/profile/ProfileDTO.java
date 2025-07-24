package NPJ.Crewer.profile;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.util.List;

@Getter
@AllArgsConstructor
public class ProfileDTO {
    private String username;
    private String nickname;
    private String avatarUrl;
    private double temperature;
    private List<String> interests;
}