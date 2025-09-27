package NPJ.Crewer.feeds.groupfeed;

import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
import NPJ.Crewer.feeds.feed.dto.FeedResponseDTO;
import NPJ.Crewer.feeds.groupfeed.dto.GroupFeedCreateDTO;
import NPJ.Crewer.feeds.groupfeed.dto.GroupFeedDetailResponseDTO;
import NPJ.Crewer.feeds.groupfeed.dto.GroupFeedResponseDTO;
import NPJ.Crewer.feeds.groupfeed.dto.GroupFeedUpdateDTO;
import NPJ.Crewer.feeds.groupfeed.dto.GroupFeedCompleteResponseDTO;
import NPJ.Crewer.notification.NotificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/groupfeeds")
@RequiredArgsConstructor
public class GroupFeedController {

    private final GroupFeedService groupFeedService;
    private final NotificationService notificationService;

    //GroupFeed 생성
    @PostMapping("/create")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<GroupFeedResponseDTO> createGroupFeed(@Valid @RequestBody GroupFeedCreateDTO groupFeedCreateDTO,
                                                                @AuthenticationPrincipal(expression = "id") Long memberId) {

        GroupFeedResponseDTO groupFeedResponseDTO = groupFeedService.createGroupFeed(groupFeedCreateDTO, memberId);

        return ResponseEntity.status(HttpStatus.CREATED).body(groupFeedResponseDTO);
    }

    //전체 GroupFeed 리스트 조회
    @GetMapping("/new")
    public ResponseEntity<Page<GroupFeedResponseDTO>> getAllNewGroupFeeds(@PageableDefault(size = 20)Pageable pageable) {//GroupFeed를 20개씩 페이지로 불러오기

        Page<GroupFeedResponseDTO> groupFeeds = groupFeedService.getAllGroupFeedsNew(pageable);
        return ResponseEntity.ok(groupFeeds);
    }

    //전체 GroupFeed 리스트 조회
    @GetMapping("/popular")
    public ResponseEntity<Page<GroupFeedResponseDTO>> getAllHotGroupFeeds(@PageableDefault(size = 20)Pageable pageable) {//GroupFeed를 20개씩 페이지로 불러오기

        Page<GroupFeedResponseDTO> groupFeeds = groupFeedService.getAllHotGroupFeeds(pageable);
        return ResponseEntity.ok(groupFeeds);
    }

    @GetMapping("/latesttwo") // HTTP GET 요청을 /api/group-feeds/latest 경로와 매핑합니다.
    public ResponseEntity<List<GroupFeedResponseDTO>> getLatestTwoGroupFeeds() {
        List<GroupFeedResponseDTO> groupFeedsFormain = groupFeedService.findLatestTwoGroupFeeds();
        return ResponseEntity.ok(groupFeedsFormain);
    }

    //Deadline이 6시간 남거나 currentParticipant/maxParticipant >=0.6 이상인 GroupFeeds
    @GetMapping("/hot")
    public ResponseEntity<Page<GroupFeedResponseDTO>> getAlmostFullGroupFeeds(@PageableDefault(size = 10)Pageable pageable) {//GroupFeed를 20개씩 페이지로 불러오기

        Page<GroupFeedResponseDTO> groupFeeds = groupFeedService.getAlmostFullGroupFeeds(pageable);
        return ResponseEntity.ok(groupFeeds);
    }

    // 모임 종료
    @PostMapping("/chatroom/{chatRoomId}/complete")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<GroupFeedCompleteResponseDTO> completeGroupFeed(
            @PathVariable String chatRoomId,
            @AuthenticationPrincipal NPJ.Crewer.member.Member member) {
        
        // Service Layer에서 모임 종료 + 알림 생성 처리 (중복 방지 포함)
        GroupFeedCompleteResponseDTO response = groupFeedService.completeGroupFeedWithNotifications(chatRoomId, member.getId());
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/mainsearch")
    public ResponseEntity<Page<GroupFeedResponseDTO>> getGroupFeedsByKeyword(@PageableDefault(size = 20) Pageable pageable, String keyword) {
        Page<GroupFeedResponseDTO> searchedGroupFeeds = groupFeedService.getGroupFeedsByKeyword(pageable, keyword);
        return ResponseEntity.ok(searchedGroupFeeds);
    }

    //GroupFeed 상세 페이지 조회
    @GetMapping("/{groupFeedId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<GroupFeedDetailResponseDTO> getGroupFeedById(@PathVariable("groupFeedId") Long groupFeedId,
                                                                       @AuthenticationPrincipal(expression = "id") Long memberId) {

        GroupFeedDetailResponseDTO groupFeed = groupFeedService.getGroupFeedById(groupFeedId, memberId);
        return ResponseEntity.ok(groupFeed);
    }

    //수정할 GroupFeed 내용 조회
    @GetMapping("/{groupFeedId}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<GroupFeedUpdateDTO> getGroupFeedForUpdate(@PathVariable("groupFeedId") Long groupFeedId,
                                                                    @AuthenticationPrincipal(expression = "id") Long memberId) {

        GroupFeedUpdateDTO groupFeedUpdateDTO = groupFeedService.getGroupFeedForUpdate(groupFeedId, memberId);
        return ResponseEntity.ok(groupFeedUpdateDTO);
    }

    //GroupFeed 수정
    @PutMapping("/{groupFeedId}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<GroupFeedResponseDTO> updateGroupFeed(@PathVariable("groupFeedId") Long groupFeedId,
                                                                @AuthenticationPrincipal(expression = "id") Long memberId,
                                                                @Valid @RequestBody GroupFeedUpdateDTO groupFeedUpdateDTO) {

        GroupFeedResponseDTO updatedGroupFeed = groupFeedService.updateGroupFeed(groupFeedId, memberId, groupFeedUpdateDTO);
        return ResponseEntity.ok(updatedGroupFeed);
    }

    //GroupFeed 삭제 (채팅방 유지 여부 선택 가능)
    @DeleteMapping("/{groupFeedId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> deleteGroupFeed(@PathVariable("groupFeedId") Long groupFeedId,
                                                @AuthenticationPrincipal(expression = "id") Long memberId,
                                                @RequestParam(name = "deleteChatRoom", required = false, defaultValue = "false")
                                                    boolean deleteChatRoom
    ) {

        groupFeedService.deleteGroupFeed(groupFeedId, memberId, deleteChatRoom);
        return ResponseEntity.noContent().build();
    }


    @PostMapping("/{groupFeedId}/join-chat")
    @PreAuthorize("isAuthenticated()")
    public ChatRoomResponseDTO joinChatRoom(@PathVariable("groupFeedId") Long groupFeedId,
                                            @AuthenticationPrincipal(expression = "id") Long memberId) {

        return groupFeedService.joinChatRoom(groupFeedId, memberId);
    }

    // 그룹 피드 참여자 목록 조회
    @GetMapping("/{groupFeedId}/participants")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<Map<String, Object>>> getGroupFeedParticipants(@PathVariable("groupFeedId") Long groupFeedId) {
        List<Map<String, Object>> participants = groupFeedService.getGroupFeedParticipants(groupFeedId);
        return ResponseEntity.ok(participants);
    }
}