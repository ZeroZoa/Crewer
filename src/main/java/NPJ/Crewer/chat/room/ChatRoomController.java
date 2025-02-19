package NPJ.Crewer.chat.room;

import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/chat/room")
@RequiredArgsConstructor
public class ChatRoomController {
    private final ChatRoomService chatRoomService;
    private final MemberService memberService;

    @PostMapping("/create")
    public ResponseEntity<?> createChatRoom(@RequestBody ChatRoomCreateDTO dto) {
        // 로그인 여부 확인
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인이 필요합니다.");
        }

        // 현재 로그인된 사용자 가져오기
        String creatorUsername = authentication.getName();

        Member member = memberService.getMember(creatorUsername);

        // 회원 정보가 없으면 403 Forbidden 반환
        if (member == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("사용자 정보를 찾을 수 없습니다.");
        }

        // 채팅방 생성
        ChatRoomDTO createdRoom = chatRoomService.createChatRoom(dto, creatorUsername);
        return ResponseEntity.ok(createdRoom);
    }

    @GetMapping
    public ResponseEntity<List<ChatRoomDTO>> getAllChatRooms() {
        return ResponseEntity.ok(chatRoomService.getAllChatRooms());
    }

    @GetMapping("/{id}")
    public ResponseEntity<ChatRoomDTO> getChatRoomById(@PathVariable Long id) {
        return ResponseEntity.ok(chatRoomService.getChatRoomById(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteChatRoom(@PathVariable Long id) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String requesterUsername = authentication.getName();

        chatRoomService.deleteChatRoom(id, requesterUsername);
        return ResponseEntity.ok("채팅방 삭제 완료");
    }
}