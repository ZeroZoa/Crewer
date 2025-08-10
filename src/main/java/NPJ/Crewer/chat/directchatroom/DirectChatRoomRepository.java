package NPJ.Crewer.chat.directchatroom;

import NPJ.Crewer.chat.chatroom.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DirectChatRoomRepository extends JpaRepository<DirectChatRoom, UUID> {
    @Query("""
    SELECT d FROM DirectChatRoom d 
    WHERE 
        (d.member1.id = :memberId1 AND d.member2.id = :memberId2) OR 
        (d.member1.id = :memberId2 AND d.member2.id = :memberId1)
    """)
    List<DirectChatRoom> findByMembers(@Param("memberId1") Long memberId1, @Param("memberId2") Long memberId2);

}