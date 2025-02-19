package NPJ.Crewer.chat.room;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> { // UUID → Long 변경
    List<ChatRoom> findAllByOrderByLastMessageAtDesc();
}