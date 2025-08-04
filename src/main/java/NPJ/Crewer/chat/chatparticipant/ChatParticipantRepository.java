package NPJ.Crewer.chat.chatparticipant;

import NPJ.Crewer.member.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChatParticipantRepository extends JpaRepository<ChatParticipant, Long> {

    // 특정 채팅방에 대해 특정 Username(id)을 가진 사용자가 참여했는지 조회
    ChatParticipant findByChatRoomIdAndMemberUsername(UUID chatRoomId, String username);

    //Member을 통해 참여중인 채팅방 조회
    List<ChatParticipant> findByMemberId(Long memberId);

    // SQL로 두명이 같은 방에 참여하고 있는 방이 있는지 조회
    @Query(value = """
    SELECT chat_room_id 
    FROM chat_participant 
    WHERE member_id IN (:member1, :member2) 
    GROUP BY chat_room_id 
    HAVING 
        COUNT(DISTINCT member_id) = 2 AND
        COUNT(*) = 2
    """, nativeQuery = true)
    List<UUID> findDirectChatRoomIdForMembers(Long member1, Long member2);
}
