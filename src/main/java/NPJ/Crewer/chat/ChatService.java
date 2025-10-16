package NPJ.Crewer.chat;

import NPJ.Crewer.chat.chatmessage.ChatMessage;
import NPJ.Crewer.chat.chatmessage.dto.ChatMessageDTO;
import NPJ.Crewer.chat.chatmessage.ChatMessageRepository;
import NPJ.Crewer.chat.chatparticipant.ChatParticipant;
import NPJ.Crewer.chat.chatparticipant.ChatParticipantRepository;
import NPJ.Crewer.chat.chatroom.ChatRoom;
import NPJ.Crewer.chat.chatroom.ChatRoomRepository;
import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
import NPJ.Crewer.chat.directchatroom.DirectChatRoomRepositoryCustom;
import NPJ.Crewer.chat.directchatroom.dto.DirectChatRoomResponseDTO;
import NPJ.Crewer.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final ChatRoomRepository chatRoomRepository;
    private final MemberRepository memberRepository;
    private final ChatParticipantRepository chatParticipantRepository;
    private final DirectChatRoomRepositoryCustom directChatRoomRepositioryCustom;

    @Value("${upload.dir}")
    private String uploadDir;


    //ChatMessage 저장
    @Transactional
    public ChatMessageDTO saveMessage(UUID chatRoomId, Long memberId, String content, String type) {
        // 채팅방 조회: 해당 채팅방이 없으면 예외 발생
        ChatRoom chatRoom = chatRoomRepository.findById(chatRoomId)
                .orElseThrow(() -> new IllegalArgumentException("채팅방을 찾을 수 없습니다."));

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // type String에서 MessageType으로 변환
        ChatMessage.MessageType messageType = ChatMessage.MessageType.valueOf(type);

        // 채팅 메시지 엔티티 생성: persistentMember를 sender로 사용
        ChatMessage message = ChatMessage.builder()
                .chatRoom(chatRoom)
                .sender(member)
                .content(content)
                .type(messageType)
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
                .type(saved.getType())
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
                .findByChatRoomIdAndMemberId(chatRoomId, memberId);

        if (participant == null) {
            // 참여 기록이 없으면 채팅방 내용 조회 권한이 없으므로 예외 발생
            throw new IllegalArgumentException("채팅방에 접근 권한이 없습니다.");
        }

        //채팅 메시지 조회: 채팅방 ID를 기준으로 채팅 메시지 목록을 조회 , 타임스탬프 기준으로 오래된것부터 뜨는 내림차순
        List<ChatMessageDTO> messages = chatMessageRepository.findByChatRoomIdWithAvatarUrl(chatRoomId);
        //각 ChatMessage 엔티티를 ChatMessageDTO로 변환하여 반환 (ChatMessage id는 Long 타입)
        return messages;//
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
                .map(chatRoom -> {
                    ChatMessage lastMessage = chatMessageRepository.findTopByChatRoomIdOrderByTimestampAtDesc(chatRoom.getId());

                    return new ChatRoomResponseDTO(
                            chatRoom.getId(),                    // UUID
                            chatRoom.getName(),                  // String
                            chatRoom.getMaxParticipants(),       // int
                            chatRoom.getCurrentParticipants(),   // 현재 인원 수
                            chatRoom.getType(),
                            lastMessage != null ? lastMessage.getTimestamp() : null,
                            lastMessage != null ? lastMessage.getContent() : null,
                            lastMessage != null ? lastMessage.getType() : null
                    );
                })
                .collect(Collectors.toList());
    }
    @Transactional(readOnly = true)
    public List<DirectChatRoomResponseDTO> getDirectChatRoomList(Long memberId){
        //사용자 예외 처리
        Member me = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // Member 객체를 통해 ChatParticipant 조회
        List<ChatParticipant> chatParticipants = chatParticipantRepository.findByMemberId(memberId);
        List<DirectChatRoomResponseDTO> directChatRoomResponseDTO = directChatRoomRepositioryCustom.findDirectChatRoomsWithAvartar(memberId);

        return  directChatRoomResponseDTO;

    }
    public ChatRoomResponseDTO getChatRoom(UUID chatRoomId){
        Optional<ChatRoom> chatRoomOptional = chatRoomRepository.findById(chatRoomId);
        ChatRoom chatRoom = chatRoomOptional.get();
        return ChatRoomResponseDTO.builder()
                .id(chatRoom.getId())
                .name(chatRoom.getName())
                .maxParticipants(chatRoom.getMaxParticipants())
                .currentParticipants(chatRoom.getCurrentParticipants())
                .type(chatRoom.getType())
                .build();
    }

    //ChatMessage 저장
    @Transactional
    public void exitChatRoom(UUID chatRoomId, Long memberId) {
        // 채팅방 조회: 해당 채팅방이 없으면 예외 발생
        ChatRoom chatRoom = chatRoomRepository.findById(chatRoomId)
                .orElseThrow(() -> new IllegalArgumentException("채팅방을 찾을 수 없습니다."));

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));
        //내가 있는 chatparticipants 가져오기
        ChatParticipant mychatroom=  chatParticipantRepository.findByChatRoomIdAndMemberId(chatRoomId, memberId);

        chatRoom.removeParticipant();
        if(chatRoom.getCurrentParticipants()==0){
            chatMessageRepository.deleteAllByChatRoomId(chatRoomId);
            chatParticipantRepository.delete(mychatroom);
            chatRoomRepository.deleteById(chatRoomId);
        }else {
            chatParticipantRepository.delete(mychatroom);
        }

    }

    public ResponseEntity<String> uploadImage(Long memberId, MultipartFile image){

        try {
            File directory = new File(uploadDir+"/chat");
            if (!directory.exists()) { // 폴더 없으면 생성
                directory.mkdirs();
            }
            // 저장할 파일 경로
            String fileName = memberId + "_" + image.getOriginalFilename();
            Path filePath = Paths.get(uploadDir + "/chat", fileName);
            String fileUrl = "/crewerimages/chat/" + fileName;

            //파일 있으면 경로만 반환
            if (Files.exists(filePath)) {
                return ResponseEntity.ok(fileUrl);
            }

            // 파일 저장 경로 반환
            Files.write(filePath, image.getBytes());

            return ResponseEntity.ok(fileUrl);
        } catch (IOException e){
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Upload Fail");
        }

    }

}
