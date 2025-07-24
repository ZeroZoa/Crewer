package NPJ.Crewer.chat.chatparticipant;

import NPJ.Crewer.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChatParticipantRepository extends JpaRepository<ChatParticipant, Long> {

    // 특정 채팅방에 대해 특정 Username(id)을 가진 사용자가 참여했는지 조회
    ChatParticipant findByChatRoomIdAndMemberUsername(UUID chatRoomId, String username);

    //Member을 통해 참여중인 채팅방 조회
    List<ChatParticipant> findByMemberId(Long memberId);
}
