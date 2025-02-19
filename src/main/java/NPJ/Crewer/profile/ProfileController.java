package NPJ.Crewer.profile;

import NPJ.Crewer.feed.Feed;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;

    // ✅ 나의 프로필 정보만 반환 (피드 제외)
    @GetMapping("/me")
    public ResponseEntity<?> getMyProfile() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인이 필요합니다.");
        }

        String username = authentication.getName();
        ProfileDTO profile = profileService.getProfile(username); // ✅ 프로필 정보만 반환
        return ResponseEntity.ok(profile);
    }

    // ✅ 나의 모든 피드 반환 (페이징 제거)
    @GetMapping("/me/feeds")
    public ResponseEntity<?> getMyFeeds() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인이 필요합니다.");
        }

        String username = authentication.getName();
        List<Feed> feeds = profileService.getFeedsByUser(username); // ✅ 모든 피드 반환
        return ResponseEntity.ok(feeds);
    }

    @GetMapping("/me/liked-feeds")
    public ResponseEntity<?> getMyLikedFeeds() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인이 필요합니다.");
        }

        String username = authentication.getName();
        List<Feed> likedFeeds = profileService.getLikedFeeds(username);
        return ResponseEntity.ok(likedFeeds);
    }
}