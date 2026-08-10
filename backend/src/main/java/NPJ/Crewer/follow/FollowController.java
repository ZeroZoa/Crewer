package NPJ.Crewer.follow;

import NPJ.Crewer.follow.dto.FollowListResponse;
import NPJ.Crewer.follow.dto.FollowStatusResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/follows")
@RequiredArgsConstructor
public class FollowController {
    
    private final FollowService followService;
    
    // 팔로우
    @PostMapping("/{username}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FollowStatusResponse> follow(
            @PathVariable String username,
            @AuthenticationPrincipal(expression = "id") Long currentMemberId) {
        
        FollowStatusResponse response = followService.follow(currentMemberId, username);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    // 언팔로우
    @DeleteMapping("/{username}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FollowStatusResponse> unfollow(
            @PathVariable String username,
            @AuthenticationPrincipal(expression = "id") Long currentMemberId) {
        
        FollowStatusResponse response = followService.unfollow(currentMemberId, username);
        return ResponseEntity.ok(response);
    }
    
    // 팔로우 상태 확인
    @GetMapping("/check/{username}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FollowStatusResponse> checkFollowStatus(
            @PathVariable String username,
            @AuthenticationPrincipal(expression = "id") Long currentMemberId) {
        
        FollowStatusResponse response = followService.getFollowStatus(currentMemberId, username);
        return ResponseEntity.ok(response);
    }
    
    // 내 팔로워 목록 조회
    @GetMapping("/followers/me")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FollowListResponse> getMyFollowers(
            @AuthenticationPrincipal(expression = "id") Long currentMemberId) {
        
        FollowListResponse response = followService.getFollowers(currentMemberId);
        return ResponseEntity.ok(response);
    }
    
    // 내 팔로잉 목록 조회
    @GetMapping("/following/me")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FollowListResponse> getMyFollowing(
            @AuthenticationPrincipal(expression = "id") Long currentMemberId) {
        
        FollowListResponse response = followService.getFollowing(currentMemberId);
        return ResponseEntity.ok(response);
    }
    
    // 팔로워 목록 조회
    @GetMapping("/followers/{username}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FollowListResponse> getFollowers(@PathVariable String username) {
        FollowListResponse response = followService.getFollowersByUsername(username);
        return ResponseEntity.ok(response);
    }
    
    // 팔로잉 목록 조회
    @GetMapping("/following/{username}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<FollowListResponse> getFollowing(@PathVariable String username) {
        FollowListResponse response = followService.getFollowingByUsername(username);
        return ResponseEntity.ok(response);
    }
} 