package NPJ.Crewer.chat;

import NPJ.Crewer.chat.chatmessage.ChatMessage;
import NPJ.Crewer.chat.chatmessage.dto.ChatMessageDTO;
import NPJ.Crewer.chat.chatmessage.ChatMessageRepository;
import NPJ.Crewer.chat.chatparticipant.ChatParticipant;
import NPJ.Crewer.chat.chatparticipant.ChatParticipantRepository;
import NPJ.Crewer.chat.chatroom.ChatRoom;
import NPJ.Crewer.chat.chatroom.ChatRoomRepository;
import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
import NPJ.Crewer.chat.directchatroom.dto.DirectChatRoomResponseDTO;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final ChatRoomRepository chatRoomRepository;
    private final MemberRepository memberRepository;
    private final ChatParticipantRepository chatParticipantRepository;

    //ChatMessage 저장
    @Transactional
    public ChatMessageDTO saveMessage(UUID chatRoomId, Long memberId, String content) {
        // 채팅방 조회: 해당 채팅방이 없으면 예외 발생
        ChatRoom chatRoom = chatRoomRepository.findById(chatRoomId)
                .orElseThrow(() -> new IllegalArgumentException("채팅방을 찾을 수 없습니다."));

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));


        // 채팅 메시지 엔티티 생성: persistentMember를 sender로 사용
        ChatMessage message = ChatMessage.builder()
                .chatRoom(chatRoom)
                .sender(member)
                .content(content)
                .timestamp(Instant.now())
                .build();

        // 메시지 저장 (저장 시 외래키 sender_id가 올바른 값이어야 함)
        ChatMessage saved = chatMessageRepository.save(message);

        // 저장된 엔티티를 DTO로 변환하여 반환
        return ChatMessageDTO.builder()
                .id(saved.getId())
                .chatRoomId(chatRoomId)
                .senderId(member.getId())
                .senderNickname(member.getNickname())
                .content(saved.getContent())
                .timestamp(saved.getTimestamp())
                .build();
    }

    //ChatMessage List 조희
    @Transactional(readOnly = true)
    public List<ChatMessageDTO> getChatList(UUID chatRoomId, Long memberId) {
        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        //채팅방 조회: chatRoomId를 이용해 채팅방을 조회하고, 없으면 예외 발생
        ChatRoom chatRoom = chatRoomRepository.findById(chatRoomId)
                .orElseThrow(() -> new IllegalArgumentException("채팅방을 찾을 수 없습니다."));

        //채팅방 참여자 조회: 채팅방에 해당 사용자가 참여했는지 확인 (getUsername 사용)
        ChatParticipant participant = chatParticipantRepository
                .findByChatRoomIdAndMemberUsername(chatRoomId, member.getUsername());

        if (participant == null) {
            // 참여 기록이 없으면 채팅방 내용 조회 권한이 없으므로 예외 발생
            throw new IllegalArgumentException("채팅방에 접근 권한이 없습니다.");
        }

        //채팅 메시지 조회: 채팅방 ID를 기준으로 채팅 메시지 목록을 조회
        List<ChatMessage> messages = chatMessageRepository.findByChatRoomId(chatRoomId);


        //각 ChatMessage 엔티티를 ChatMessageDTO로 변환하여 반환 (ChatMessage id는 Long 타입)
        return messages.stream().map(chatMessage -> ChatMessageDTO.builder()
                .id(chatMessage.getId())               // Long 타입의 채팅 메시지 id
                .chatRoomId(chatRoomId)                 // 채팅방의 UUID
                .senderId(chatMessage.getSender().getId())  // 메시지를 보낸 사용자의 id
                .senderNickname(chatMessage.getSender().getNickname()) //메세지를 보낸 사용자의 nickName
                .content(chatMessage.getContent())      // 메시지 내용
                .timestamp(chatMessage.getTimestamp())  // 메시지 전송 시각
                .build()
        ).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ChatRoomResponseDTO> getGroupChatRoomList(Long memberId){
        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // Member 객체를 통해 ChatParticipant 조회
        List<ChatParticipant> chatParticipants = chatParticipantRepository.findByMemberId(memberId);

        // ChatRoom을 추출하여 DTO로 직접 생성
        return chatParticipants.stream()
                .map(ChatParticipant::getChatRoom)
                .filter(chatRoom ->chatRoom.getType() == ChatRoom.ChatRoomType.GROUP)
                .distinct()
                .map(chatRoom -> new ChatRoomResponseDTO(
                        chatRoom.getId(),                    // UUID
                        chatRoom.getName(),                  // String
                        chatRoom.getMaxParticipants(),       // int
                        chatRoom.getCurrentParticipants()   // 현재 인원 수
                ))
                .collect(Collectors.toList());
    }
    @Transactional(readOnly = true)
    public List<DirectChatRoomResponseDTO> getDirectChatRoomList(Long memberId){
        //사용자 예외 처리
        Member me = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // Member 객체를 통해 ChatParticipant 조회
        List<ChatParticipant> chatParticipants = chatParticipantRepository.findByMemberId(memberId);



        // ChatRoom을 추출하여 DTO로 직접 생성
        return chatParticipants.stream()
                .map(ChatParticipant::getChatRoom)
                .filter(chatRoom ->chatRoom.getType() == ChatRoom.ChatRoomType.DIRECT)
                .distinct()
                .map(chatRoom -> {
                    List<Member> members = chatParticipantRepository.findByChatRoomId(chatRoom.getId())
                            .stream()
                            .map(ChatParticipant::getMember)
                            .collect(Collectors.toList());

                    Member other  = members.stream()
                            .filter(m -> !m.getId().equals(memberId))
                            .findFirst()
                            .orElse(null);

                    String title = (other != null) ? other.getNickname() : "알 수 없음";

                    return new DirectChatRoomResponseDTO(
                            chatRoom.getId(),                    // UUID
                            title,                 // String
                            chatRoom.getMaxParticipants(),       // int
                            chatRoom.getCurrentParticipants()   // 현재 인원 수
                    );
                })
                .collect(Collectors.toList());
    }
}
