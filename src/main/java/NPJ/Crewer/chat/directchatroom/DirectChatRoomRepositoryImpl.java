package NPJ.Crewer.chat.directchatroom;

import NPJ.Crewer.chat.chatmessage.QChatMessage;
import NPJ.Crewer.chat.chatparticipant.QChatParticipant;
import NPJ.Crewer.chat.chatroom.ChatRoom;
import NPJ.Crewer.chat.chatroom.QChatRoom;
import NPJ.Crewer.chat.directchatroom.dto.DirectChatRoomResponseDTO;
import NPJ.Crewer.member.QMember;
import com.querydsl.core.types.Projections;
import com.querydsl.jpa.JPAExpressions;
import org.springframework.stereotype.Repository;
import com.querydsl.jpa.impl.JPAQueryFactory;

import java.util.List;

@Repository
public class DirectChatRoomRepositoryImpl implements DirectChatRoomRepositoryCustom {
    private final JPAQueryFactory queryFactory;

    private final QChatRoom chatRoom = QChatRoom.chatRoom;
    private final QChatMessage chatMessage = QChatMessage.chatMessage;
    QChatMessage latestMessage = new QChatMessage("latestMessage");
    QChatParticipant me = new QChatParticipant("me");
    QChatParticipant other = new QChatParticipant("other");
    private final QMember member = QMember.member; // 상대방을 찾기 위한 Member

    public DirectChatRoomRepositoryImpl(JPAQueryFactory queryFactory) {
        this.queryFactory = queryFactory;
    }

    @Override
    public List<DirectChatRoomResponseDTO> findDirectChatRoomsWithAvartar(Long myUserId) {

        return queryFactory
                .select(Projections.fields(DirectChatRoomResponseDTO.class,
                        // ChatRoom 필드들
                        chatRoom.id,
                        chatRoom.name,
                        chatRoom.maxParticipants,
                        chatRoom.currentParticipants,
                        chatMessage.timestamp.as("lastSendAt"),
                        chatMessage.content.as("lastContent"),
                        chatMessage.type.as("lastType"),
                        member.nickname,
                        member.profile.avatarUrl.as("avatarUrl")
                ))
                .distinct()
                .from(chatRoom)

                // 실제 참여자 테이블을 사용해 나와 상대방을 구분하는 JOIN 로직 필요
                // 예시: chatRoom에 연결된 참여자(member) 중 내가 아닌 사람을 찾음
                .join(me).on(me.chatRoom.eq(chatRoom))
                .join(other).on(other.chatRoom.eq(chatRoom))
                .join(other.member, member)
                .leftJoin(chatMessage).on(
                        // 1. ChatMessage가 현재 ChatRoom에 속해 있어야 하고
                        chatMessage.chatRoom.eq(chatRoom)
                                // 2. ⭐ ChatMessage의 ID가 이 방에서 가장 큰(최신) ID와 같아야 한다.
                                .and(chatMessage.id.eq(
                                        JPAExpressions
                                                .select(latestMessage.id.max()) // 이 방의 메시지 중 ID가 가장 큰 것을 선택
                                                .from(latestMessage)
                                                .where(latestMessage.chatRoom.eq(chatRoom)) // 현재 ChatRoom의 메시지만 대상
                                ))
                )
                .where(
                        me.member.id.eq(myUserId)
                                .and(other.member.id.ne(myUserId))
                                .and(chatRoom.maxParticipants.eq(2))
                                .and(chatRoom.type.eq(ChatRoom.ChatRoomType.DIRECT))
                )
                .fetch(); // 완성된 쿼리 결과 반환
    }
}
