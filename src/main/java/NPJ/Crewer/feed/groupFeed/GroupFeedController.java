package NPJ.Crewer.feed.groupFeed;

import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
import NPJ.Crewer.feed.groupFeed.dto.GroupFeedCreateDTO;
import NPJ.Crewer.feed.groupFeed.dto.GroupFeedResponseDTO;
import NPJ.Crewer.feed.groupFeed.dto.GroupFeedUpdateDTO;
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

@RestController
@RequestMapping("/groupfeeds")
@RequiredArgsConstructor
public class GroupFeedController {

    private final GroupFeedService groupFeedService;

    //GroupFeed 생성
    @PostMapping("/create")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<GroupFeedResponseDTO> createGroupFeed(@Valid @RequestBody GroupFeedCreateDTO groupFeedCreateDTO,
                                                                @AuthenticationPrincipal(expression = "id") Long memberId) {

        GroupFeedResponseDTO groupFeedResponseDTO = groupFeedService.createGroupFeed(groupFeedCreateDTO, memberId);
        return ResponseEntity.status(HttpStatus.CREATED).body(groupFeedResponseDTO);
    }

    //전체 GroupFeed 리스트 조회
    @GetMapping
    public ResponseEntity<Page<GroupFeedResponseDTO>> getAllGroupFeeds(@PageableDefault(size = 20)Pageable pageable) {//GroupFeed를 20개씩 페이지로 불러오기

        Page<GroupFeedResponseDTO> groupFeeds = groupFeedService.getAllGroupFeeds(pageable);
        return ResponseEntity.ok(groupFeeds);
    }

    //GroupFeed 상세 페이지 조회
    @GetMapping("/{groupFeedId}")
    public ResponseEntity<GroupFeedResponseDTO> getGroupFeedById(@PathVariable("groupFeedId") Long groupFeedId) {

        GroupFeedResponseDTO groupFeedResponseDTO = groupFeedService.getGroupFeedById(groupFeedId);
        return ResponseEntity.ok(groupFeedResponseDTO);
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
}