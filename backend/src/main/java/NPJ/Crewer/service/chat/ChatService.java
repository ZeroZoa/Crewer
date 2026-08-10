package NPJ.Crewer.service.chat;

import NPJ.Crewer.domain.chat.chatmessage.ChatMessage;
import NPJ.Crewer.dto.chat.chatmessage.ChatMessageDTO;
import NPJ.Crewer.repository.chat.chatmessage.ChatMessageRepository;
import NPJ.Crewer.domain.chat.chatparticipant.ChatParticipant;
import NPJ.Crewer.repository.chat.chatparticipant.ChatParticipantRepository;
import NPJ.Crewer.domain.chat.chatroom.ChatRoom;
import NPJ.Crewer.repository.chat.chatroom.ChatRoomRepository;
import NPJ.Crewer.dto.chat.chatroom.ChatRoomResponseDTO;
import NPJ.Crewer.repository.chat.directchatroom.DirectChatRoomRepositoryCustom;
import NPJ.Crewer.dto.chat.directchatroom.DirectChatRoomResponseDTO;
import NPJ.Crewer.domain.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.domain.member.Member;
import NPJ.Crewer.repository.member.MemberRepository;
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

        // 해당 채팅방 참여자만 메시지를 보낼 수 있음
        ChatParticipant participant = chatParticipantRepository.findByChatRoomIdAndMemberId(chatRoomId, memberId);
        if (participant == null) {
            throw new IllegalArgumentException("채팅방에 참여하고 있지 않습니다.");
        }

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
    @Transactional(readOnly = true)
    public ChatRoomResponseDTO getChatRoom(UUID chatRoomId, Long memberId){
        ChatRoom chatRoom = chatRoomRepository.findById(chatRoomId)
                .orElseThrow(() -> new IllegalArgumentException("채팅방을 찾을 수 없습니다."));

        // 채팅방 참여자만 조회 가능
        ChatParticipant participant = chatParticipantRepository.findByChatRoomIdAndMemberId(chatRoomId, memberId);
        if (participant == null) {
            throw new IllegalArgumentException("채팅방에 접근 권한이 없습니다.");
        }

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
        if (mychatroom == null) {
            throw new IllegalArgumentException("채팅방에 참여하고 있지 않습니다.");
        }

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
            // 클라이언트가 보낸 원본 파일명을 경로에 그대로 쓰지 않는다 (path traversal 방지)
            String fileName = memberId + "_" + UUID.randomUUID() + extractExtension(image.getOriginalFilename());
            Path filePath = Paths.get(uploadDir + "/chat", fileName);
            String fileUrl = "/crewerimages/chat/" + fileName;

            Files.write(filePath, image.getBytes());

            return ResponseEntity.ok(fileUrl);
        } catch (IOException e){
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Upload Fail");
        }

    }

    private String extractExtension(String originalFilename) {
        if (originalFilename == null) {
            return "";
        }
        int dotIndex = originalFilename.lastIndexOf('.');
        if (dotIndex < 0) {
            return "";
        }
        return originalFilename.substring(dotIndex).replaceAll("[^a-zA-Z0-9.]", "");
    }

}
