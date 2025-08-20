package NPJ.Crewer.chat.directchatroom;

import NPJ.Crewer.chat.chatroom.ChatRoom;
import NPJ.Crewer.member.Member;
import jakarta.persistence.*;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@Getter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class DirectChatRoom extends ChatRoom {

    @ManyToOne(optional = false)
    @JoinColumn(name = "member_id1")
    private Member member1;

    @ManyToOne(optional = false)
    @JoinColumn(name = "member_id2")
    private Member member2;




}



