package NPJ.Crewer.chat.chatmessage;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    // 채팅방 ID로 해당 채팅방의 모든 메시지를 조회하는 메서드
    List<ChatMessage> findByChatRoomId(UUID chatRoomId);
}
