package NPJ.Crewer.directChat;

import NPJ.Crewer.chat.chatparticipant.ChatParticipant;
import NPJ.Crewer.chat.chatparticipant.ChatParticipantRepository;
import NPJ.Crewer.chat.chatroom.ChatRoom;
import NPJ.Crewer.chat.chatroom.ChatRoomRepository;
import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
import NPJ.Crewer.feed.groupFeed.GroupFeedRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

@RequiredArgsConstructor
@Service
public class DirectChatService {

    private final GroupFeedRepository groupFeedRepository;

    private final ChatRoomRepository chatRoomRepository;
    private final ChatParticipantRepository chatParticipantRepository;
    private final MemberRepository memberRepository;

    @Transactional
    public ChatRoomResponseDTO joinChatRoom(String username, Long memberId) {
        //받는 사용자 예외 처리
        Member receiveMember = memberRepository.findByUsername(username)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        //보내는 사용자 예외 처리
        Member sendMember = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));


        // DirectChatRoom 생성 + 두 멤버 참여
        if(chatParticipantRepository.
                findDirectChatRoomIdForMembers(receiveMember.getId(), sendMember.getId()).isEmpty()
        ) {
            ChatRoom chatRoom = ChatRoom.builder()
                    .name(receiveMember.getNickname() + " 와 " + sendMember.getNickname())
                    .maxParticipants(2)
                    .build();
            chatRoomRepository.save(chatRoom);

            // ChatRoom의 currentParticipants 업데이트 (도메인 메서드 활용)
            chatRoom.addParticipant();
            ChatParticipant participant = ChatParticipant.builder()
                    .chatRoom(chatRoom)
                    .member(receiveMember)
                    .build();
            chatParticipantRepository.save(participant);

            chatRoom.addParticipant();
            ChatParticipant sendParticipant = ChatParticipant.builder()
                    .chatRoom(chatRoom)
                    .member(sendMember)
                    .build();
            chatParticipantRepository.save(sendParticipant);
       }

        // 두명이 참여하고 있는 채팅방 ID중 가장 첫번째 방ID 반환 후 방 객체 반환
        UUID chatRoomId =  chatParticipantRepository.
                findDirectChatRoomIdForMembers(receiveMember.getId(), sendMember.getId()).get(0);
        ChatRoom chatRoom =  chatRoomRepository.findById(chatRoomId).orElseThrow(() -> new EntityNotFoundException("채팅방 정보가 없습니다."));

        // ChatRoom 정보를 Builder로 DTO에 변환하여 반환
        return ChatRoomResponseDTO.builder()
                .id(chatRoom.getId())
                .name(chatRoom.getName())
                .maxParticipants(chatRoom.getMaxParticipants())
                .currentParticipants(chatRoom.getCurrentParticipants())
                .build();



//        // 이미 참여 중인 경우, capacity 체크 없이 바로 반환
//        ChatParticipant existingParticipant = chatParticipantRepository
//                .findByChatRoomIdAndMemberUsername(chatRoom.getId(), sendMember.getUsername());
//        if (existingParticipant != null) {
//            return ChatRoomResponseDTO.builder()
//                    .id(chatRoom.getId())
//                    .name(chatRoom.getName())
//                    .maxParticipants(chatRoom.getMaxParticipants())
//                    .currentParticipants(chatRoom.getCurrentParticipants())
//                    .build();
//        }

//        // 정원 체크: 현재 참가 인원이 최대 인원과 같거나 많으면 예외 발생
//        if (chatRoom.getCurrentParticipants() >= chatRoom.getMaxParticipants()) {
//            throw new IllegalStateException("정원이 초과되어 참가할 수 없습니다.");
//        }




    }

}
