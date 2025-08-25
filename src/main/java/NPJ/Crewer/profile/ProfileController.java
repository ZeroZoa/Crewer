package NPJ.Crewer.profile;

import NPJ.Crewer.feeds.feed.dto.FeedResponseDTO;
import NPJ.Crewer.follow.FollowService;
import NPJ.Crewer.follow.dto.FollowListResponse;
import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.List;

@RestController
@RequestMapping("/profile")
@RequiredArgsConstructor
public class ProfileController {
    private final ProfileService profileService;
    private final FollowService followService;

    //나의 프로필 정보 반환 (피드 제외)
    @GetMapping("/me")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ProfileDTO> getMyProfile(@AuthenticationPrincipal(expression = "id") Long memberId) {

        ProfileDTO profileDTO = profileService.getMyProfile(memberId);
        return ResponseEntity.ok(profileDTO);
    }


    //나의 모든 피드 반환
    @GetMapping("/me/feeds")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<FeedResponseDTO>> getMyFeeds(@AuthenticationPrincipal(expression = "id") Long memberId) {
        List<FeedResponseDTO> feeds = profileService.getMyFeeds(memberId);
        return ResponseEntity.ok(feeds);
    }



    //내가 좋아요한 피드 반환
    @GetMapping("/me/liked-feeds")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<FeedResponseDTO>> getMyLikedFeeds(@AuthenticationPrincipal(expression = "id") Long memberId) {
        List<FeedResponseDTO> likedFeeds = profileService.getMyLikedFeeds(memberId);
        return ResponseEntity.ok(likedFeeds);
    }

    
    //내 프로필의 관심사 수정
    @PutMapping("/me/interests")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<String>> updateMyInterests(
            @AuthenticationPrincipal(expression = "id") Long memberId,
            @RequestBody List<String> interests) {
        List<String> updated = profileService.updateInterests(memberId, interests);
        return ResponseEntity.ok(updated);
    }

    //내 닉네임 수정
    @PutMapping("/me/nickname")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<String> updateMyNickname(
            @AuthenticationPrincipal(expression = "id") Long memberId,
            @RequestBody String nickname) {
        String updated = profileService.updateNickname(memberId, nickname);
        return ResponseEntity.ok(updated);
    }

    //다른 사용자의 프로필 정보 반환
    @GetMapping("/{username}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ProfileDTO> getUserProfile(@PathVariable String username, @AuthenticationPrincipal(expression = "id") Long memberId) {
        ProfileDTO profileDTO = profileService.getProfileByUsername(username);
        return ResponseEntity.ok(profileDTO);
    }

    //다른 사용자의 피드 반환
    @GetMapping("/{username}/feeds")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<FeedResponseDTO>> getUserFeeds(@PathVariable String username, @AuthenticationPrincipal(expression = "id") Long memberId) {
        Member targetMember = profileService.getMemberByUsername(username);
        List<FeedResponseDTO> feeds = profileService.getMyFeeds(targetMember.getId());
        return ResponseEntity.ok(feeds);
    }
    
    // 내 팔로워 목록 조회
    @GetMapping("/me/followers")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FollowListResponse> getMyFollowers(@AuthenticationPrincipal(expression = "id") Long memberId) {
        FollowListResponse response = followService.getFollowers(memberId);
        return ResponseEntity.ok(response);
    }
    
    // 내 팔로잉 목록 조회
    @GetMapping("/me/following")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FollowListResponse> getMyFollowing(@AuthenticationPrincipal(expression = "id") Long memberId) {
        FollowListResponse response = followService.getFollowing(memberId);
        return ResponseEntity.ok(response);
    }
    
    // 특정 사용자의 팔로워 목록 조회
    @GetMapping("/{username}/followers")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FollowListResponse> getUserFollowers(@PathVariable String username) {
        FollowListResponse response = followService.getFollowersByUsername(username);
        return ResponseEntity.ok(response);
    }
    
    // 특정 사용자의 팔로잉 목록 조회
    @GetMapping("/{username}/following")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FollowListResponse> getUserFollowing(@PathVariable String username) {
        FollowListResponse response = followService.getFollowingByUsername(username);
        return ResponseEntity.ok(response);
    }
}