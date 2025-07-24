package NPJ.Crewer.profile;

import NPJ.Crewer.feed.normalFeed.dto.FeedResponseDTO;
import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/profile")
@RequiredArgsConstructor
public class ProfileController {
    private final ProfileService profileService;

    //나의 프로필 정보 반환 (피드 제외)
    @GetMapping("/me")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ProfileDTO> getMyProfile(@AuthenticationPrincipal(expression = "id") Long memberId) {

        ProfileDTO profileDTO = profileService.getProfile(memberId);
        return ResponseEntity.ok(profileDTO);
    }


    //나의 모든 피드 반환
    @GetMapping("/me/feeds")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<FeedResponseDTO>> getMyFeeds(@AuthenticationPrincipal Member member) {
        List<FeedResponseDTO> feeds = profileService.getFeedsByUser(member);
        return ResponseEntity.ok(feeds);
    }



    //내가 좋아요한 피드 반환
    @GetMapping("/me/liked-feeds")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<FeedResponseDTO>> getMyLikedFeeds(@AuthenticationPrincipal Member member) {
        List<FeedResponseDTO> likedFeeds = profileService.getLikedFeeds(member);
        return ResponseEntity.ok(likedFeeds);
    }
}