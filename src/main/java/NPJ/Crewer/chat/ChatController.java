package NPJ.Crewer.chat;

import NPJ.Crewer.chat.chatmessage.dto.ChatMessageDTO;
import NPJ.Crewer.chat.chatmessage.dto.ChatMessagePayloadDTO;
import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.*;


import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/chat")
public class ChatController {

    private final SimpMessagingTemplate messagingTemplate;
    private final MemberRepository memberRepository;
    private final ChatService chatService;

    @MessageMapping("/{chatRoomId}/send")
    @PreAuthorize("isAuthenticated()")
    public void sendMessage(
            @DestinationVariable String chatRoomId,
            @Payload ChatMessagePayloadDTO payload,
            StompHeaderAccessor accessor) {

        // 웹소켓 세션에서 MemberId 가져오기
        Long memberId = (Long) accessor.getSessionAttributes().get("memberId");

        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new UsernameNotFoundException("회원을 찾을 수 없습니다."));

        ChatMessageDTO savedMessage = chatService.saveMessage(
                UUID.fromString(chatRoomId),
                member,
                payload.getContent()
        );
        messagingTemplate.convertAndSend("/topic/chat/" + chatRoomId, savedMessage);
    }

    @GetMapping("/{chatRoomId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<ChatMessageDTO>> getChatHistory(
            @PathVariable UUID chatRoomId,
            @AuthenticationPrincipal Member member) {

        // ChatService의 getChatList 메서드를 호출하여 채팅 기록을 조회합니다.
        // 내부에서 chatRoomId로 채팅방 존재 여부, 참여자 권한 등을 확인합니다.
        List<ChatMessageDTO> chatMessages = chatService.getChatList(chatRoomId, member);

        // 조회된 채팅 메시지 목록을 HTTP 200 OK 상태와 함께 반환합니다.
        return ResponseEntity.ok(chatMessages);
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<ChatRoomResponseDTO>> getMyChatRooms(@AuthenticationPrincipal Member member) {
        List<ChatRoomResponseDTO> rooms = chatService.getChatRoomList(member);
        return ResponseEntity.ok(rooms);
    }
}
