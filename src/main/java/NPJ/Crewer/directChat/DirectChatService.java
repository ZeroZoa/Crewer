package NPJ.Crewer.directChat;

import NPJ.Crewer.chat.chatparticipant.ChatParticipant;
import NPJ.Crewer.chat.chatparticipant.ChatParticipantRepository;
import NPJ.Crewer.chat.chatroom.ChatRoom;
import NPJ.Crewer.chat.directchatroom.DirectChatRoom;
import NPJ.Crewer.chat.directchatroom.DirectChatRoomRepository;
import NPJ.Crewer.chat.directchatroom.dto.DirectChatRoomResponseDTO;

import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@RequiredArgsConstructor
@Service
public class DirectChatService {


    private final DirectChatRoomRepository directChatRoomRepository;
    private final ChatParticipantRepository chatParticipantRepository;
    private final MemberRepository memberRepository;

    @Transactional
    public DirectChatRoomResponseDTO joinChatRoom(String username, Long memberId) {
        //받는 사용자 예외 처리
        Member opponent = memberRepository.findByUsername(username)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        //보내는 사용자 예외 처리
        Member me = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));


        // DirectChatRoom 생성 + 두 멤버 참여
        if (directChatRoomRepository.findByMembers(me.getId(), opponent.getId()).isEmpty()) {
            DirectChatRoom directChatRoom = DirectChatRoom.builder()
                    .name(opponent.getNickname() + " 와 " + me.getNickname())
                    .maxParticipants(2)
                    .member1(opponent)
                    .member2(me)
                    .type(ChatRoom.ChatRoomType.DIRECT)
                    .build();
            directChatRoomRepository.save(directChatRoom);

            // ChatRoom의 currentParticipants 업데이트 (도메인 메서드 활용)
            directChatRoom.addParticipant();
            ChatParticipant participant = ChatParticipant.builder()
                    .chatRoom(directChatRoom)
                    .member(me)
                    .build();
            chatParticipantRepository.save(participant);

            directChatRoom.addParticipant();
            ChatParticipant sendParticipant = ChatParticipant.builder()
                    .chatRoom(directChatRoom)
                    .member(opponent)
                    .build();
            chatParticipantRepository.save(sendParticipant);
        }

        // 두명이 참여하고 있는 채팅방 ID중 가장 첫번째 방ID 반환 후 방 객체 반환

        DirectChatRoom directChatRoom = directChatRoomRepository.findByMembers(me.getId(), opponent.getId()).get(0);

        // ChatRoom 정보를 Builder로 DTO에 변환하여 반환
        return DirectChatRoomResponseDTO.builder()
                .id(directChatRoom.getId())
                .name(directChatRoom.getName())
                .maxParticipants(directChatRoom.getMaxParticipants())
                .currentParticipants(directChatRoom.getCurrentParticipants())
                .build();

    }
}
