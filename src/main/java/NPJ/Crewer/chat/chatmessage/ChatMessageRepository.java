package NPJ.Crewer.chat.chatmessage;

import NPJ.Crewer.chat.chatmessage.dto.ChatMessageDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    // 채팅방 ID로 해당 채팅방의 모든 메시지를 조회하는 메서드
    List<ChatMessage> findByChatRoomIdOrderByTimestampDesc(UUID chatRoomId);
    // 방 id로 마지막 채팅 메세지를 조회함
    @Query("SELECT m FROM ChatMessage m WHERE m.chatRoom.id = :roomId ORDER BY m.timestamp DESC LIMIT 1")
    ChatMessage findTopByChatRoomIdOrderByTimestampAtDesc(@Param("roomId") UUID roomId);

    // DTO 프로젝션으로 avatarurl을 추가해서 Dto를 생성함
    @Query("SELECT new NPJ.Crewer.chat.chatmessage.dto.ChatMessageDTO(" +
            "cm.id, " +
            "cm.chatRoom.id, " +
            "s.iD, " +
            "s.nickname, " +
            "cm.content, " +
            "cm.type, " +
            "cm.timestamp, " +
            "s.profile.avatarUrl) "+
            "FROM ChatMessage cm JOIN cm.sender s "+
            "WHERE cm.chatRoom.id = :chatRoomId " +
            "ORDER BY cm.timestamp DESC")
    List<ChatMessageDTO> findByChatRoomIdWithAvatarUrl(@Param("chatRoomId") UUID chatRoomId);

}
