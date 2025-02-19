package NPJ.Crewer.chat.room;

import NPJ.Crewer.chat.participant.ChatParticipant;
import NPJ.Crewer.chat.participant.ChatParticipantDTO;
import NPJ.Crewer.chat.participant.ChatParticipantRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatRoomService {
    private final ChatRoomRepository chatRoomRepository;
    private final ChatParticipantRepository chatParticipantRepository;
    private final MemberService memberService;

    @Transactional
    public ChatRoomDTO createChatRoom(ChatRoomCreateDTO dto, String creatorUsername) {
        Member creator = memberService.getMember(creatorUsername);

        ChatRoom chatRoom = ChatRoom.builder()
                .name(dto.getName())
                .type(dto.getType())
                .owner(creator)
                .build();
        chatRoom = chatRoomRepository.save(chatRoom);

        ChatParticipant participant = ChatParticipant.builder()
                .chatRoom(chatRoom)
                .member(creator)
                .build();
        chatParticipantRepository.save(participant);

        return new ChatRoomDTO(
                chatRoom.getId(),
                chatRoom.getName(),
                chatRoom.getType(),
                creator.getId(),
                Set.of(new ChatParticipantDTO(creator.getId(), creator.getNickname())),
                chatRoom.getCreatedAt(),
                chatRoom.getLastMessageAt()
        );
    }

    public List<ChatRoomDTO> getAllChatRooms() {
        return chatRoomRepository.findAllByOrderByLastMessageAtDesc().stream()
                .map(room -> new ChatRoomDTO(
                        room.getId(),
                        room.getName(),
                        room.getType(),
                        room.getOwner().getId(),
                        room.getParticipants().stream()
                                .map(p -> new ChatParticipantDTO(
                                        p.getMember().getId(),
                                        p.getMember().getNickname()
                                ))
                                .collect(Collectors.toSet()),
                        room.getCreatedAt(),
                        room.getLastMessageAt()
                ))
                .collect(Collectors.toList());
    }

    public ChatRoomDTO getChatRoomById(Long id) { // UUID → Long 변경
        ChatRoom chatRoom = chatRoomRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("채팅방을 찾을 수 없습니다."));

        return new ChatRoomDTO(
                chatRoom.getId(),
                chatRoom.getName(),
                chatRoom.getType(),
                chatRoom.getOwner().getId(),
                chatRoom.getParticipants().stream()
                        .map(p -> new ChatParticipantDTO(
                                p.getMember().getId(),
                                p.getMember().getNickname()
                        ))
                        .collect(Collectors.toSet()),
                chatRoom.getCreatedAt(),
                chatRoom.getLastMessageAt()
        );
    }

    @Transactional
    public void deleteChatRoom(Long chatRoomId, String requesterUsername) {
        ChatRoom chatRoom = chatRoomRepository.findById(chatRoomId)
                .orElseThrow(() -> new IllegalArgumentException("채팅방을 찾을 수 없습니다."));
        Member requester = memberService.getMember(requesterUsername);

        if (!chatRoom.getOwner().equals(requester)) {
            throw new IllegalStateException("채팅방을 삭제할 권한이 없습니다.");
        }

        chatRoomRepository.delete(chatRoom);
    }
}