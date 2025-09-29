package NPJ.Crewer.chat.directchatroom;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;
import com.querydsl.core.types.dsl.PathInits;


/**
 * QDirectChatRoom is a Querydsl query type for DirectChatRoom
 */
@Generated("com.querydsl.codegen.DefaultEntitySerializer")
public class QDirectChatRoom extends EntityPathBase<DirectChatRoom> {

    private static final long serialVersionUID = 1077559506L;

    private static final PathInits INITS = PathInits.DIRECT2;

    public static final QDirectChatRoom directChatRoom = new QDirectChatRoom("directChatRoom");

    public final NPJ.Crewer.chat.chatroom.QChatRoom _super = new NPJ.Crewer.chat.chatroom.QChatRoom(this);

    //inherited
    public final DateTimePath<java.time.Instant> createdAt = _super.createdAt;

    //inherited
    public final NumberPath<Integer> currentParticipants = _super.currentParticipants;

    //inherited
    public final ComparablePath<java.util.UUID> id = _super.id;

    //inherited
    public final NumberPath<Integer> maxParticipants = _super.maxParticipants;

    public final NPJ.Crewer.member.QMember member1;

    public final NPJ.Crewer.member.QMember member2;

    //inherited
    public final StringPath name = _super.name;

    //inherited
    public final EnumPath<NPJ.Crewer.chat.chatroom.ChatRoom.ChatRoomType> type = _super.type;

    //inherited
    public final DateTimePath<java.time.Instant> updatedAt = _super.updatedAt;

    public QDirectChatRoom(String variable) {
        this(DirectChatRoom.class, forVariable(variable), INITS);
    }

    public QDirectChatRoom(Path<? extends DirectChatRoom> path) {
        this(path.getType(), path.getMetadata(), PathInits.getFor(path.getMetadata(), INITS));
    }

    public QDirectChatRoom(PathMetadata metadata) {
        this(metadata, PathInits.getFor(metadata, INITS));
    }

    public QDirectChatRoom(PathMetadata metadata, PathInits inits) {
        this(DirectChatRoom.class, metadata, inits);
    }

    public QDirectChatRoom(Class<? extends DirectChatRoom> type, PathMetadata metadata, PathInits inits) {
        super(type, metadata, inits);
        this.member1 = inits.isInitialized("member1") ? new NPJ.Crewer.member.QMember(forProperty("member1"), inits.get("member1")) : null;
        this.member2 = inits.isInitialized("member2") ? new NPJ.Crewer.member.QMember(forProperty("member2"), inits.get("member2")) : null;
    }

}

