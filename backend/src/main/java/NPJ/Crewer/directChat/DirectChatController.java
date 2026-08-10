package NPJ.Crewer.directChat;

import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
import NPJ.Crewer.chat.directchatroom.dto.DirectChatRoomResponseDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;



@RequestMapping("/directChat")
@RestController
@RequiredArgsConstructor
public class DirectChatController {

    private final DirectChatService directChatService;

    @PostMapping("/{username}/join-chat")
    @PreAuthorize("isAuthenticated()")
    public DirectChatRoomResponseDTO joinChatRoom(@PathVariable("username") String username,
                                            @AuthenticationPrincipal(expression = "id") Long memberId) {

        return directChatService.joinChatRoom(username, memberId);
    }
}
