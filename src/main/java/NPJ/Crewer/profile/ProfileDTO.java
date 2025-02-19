package NPJ.Crewer.profile;

import NPJ.Crewer.feed.Feed;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

@Getter
@AllArgsConstructor
public class ProfileDTO {
    private String username;
    private String nickname;
    private String avatarUrl;
}