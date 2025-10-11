package NPJ.Crewer.feeds.groupfeed;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;
import com.querydsl.core.types.dsl.PathInits;


/**
 * QGroupFeed is a Querydsl query type for GroupFeed
 */
@Generated("com.querydsl.codegen.DefaultEntitySerializer")
public class QGroupFeed extends EntityPathBase<GroupFeed> {

    private static final long serialVersionUID = 1260091929L;

    private static final PathInits INITS = PathInits.DIRECT2;

    public static final QGroupFeed groupFeed = new QGroupFeed("groupFeed");

    public final NPJ.Crewer.member.QMember author;

    public final NPJ.Crewer.chat.chatroom.QChatRoom chatRoom;

    public final ListPath<NPJ.Crewer.comments.groupfeedcomment.GroupFeedComment, NPJ.Crewer.comments.groupfeedcomment.QGroupFeedComment> comments = this.<NPJ.Crewer.comments.groupfeedcomment.GroupFeedComment, NPJ.Crewer.comments.groupfeedcomment.QGroupFeedComment>createList("comments", NPJ.Crewer.comments.groupfeedcomment.GroupFeedComment.class, NPJ.Crewer.comments.groupfeedcomment.QGroupFeedComment.class, PathInits.DIRECT2);

    public final StringPath content = createString("content");

    public final DateTimePath<java.time.Instant> createdAt = createDateTime("createdAt", java.time.Instant.class);

    public final DateTimePath<java.time.Instant> deadline = createDateTime("deadline", java.time.Instant.class);

    public final NumberPath<Long> id = createNumber("id", Long.class);

    public final NumberPath<Double> latitude = createNumber("latitude", Double.class);

    public final ListPath<NPJ.Crewer.likes.likegroupfeed.LikeGroupFeed, NPJ.Crewer.likes.likegroupfeed.QLikeGroupFeed> likes = this.<NPJ.Crewer.likes.likegroupfeed.LikeGroupFeed, NPJ.Crewer.likes.likegroupfeed.QLikeGroupFeed>createList("likes", NPJ.Crewer.likes.likegroupfeed.LikeGroupFeed.class, NPJ.Crewer.likes.likegroupfeed.QLikeGroupFeed.class, PathInits.DIRECT2);

    public final NumberPath<Double> longitude = createNumber("longitude", Double.class);

    public final StringPath meetingPlace = createString("meetingPlace");

    public final EnumPath<GroupFeedStatus> status = createEnum("status", GroupFeedStatus.class);

    public final StringPath title = createString("title");

    public final DateTimePath<java.time.Instant> updatedAt = createDateTime("updatedAt", java.time.Instant.class);

    public QGroupFeed(String variable) {
        this(GroupFeed.class, forVariable(variable), INITS);
    }

    public QGroupFeed(Path<? extends GroupFeed> path) {
        this(path.getType(), path.getMetadata(), PathInits.getFor(path.getMetadata(), INITS));
    }

    public QGroupFeed(PathMetadata metadata) {
        this(metadata, PathInits.getFor(metadata, INITS));
    }

    public QGroupFeed(PathMetadata metadata, PathInits inits) {
        this(GroupFeed.class, metadata, inits);
    }

    public QGroupFeed(Class<? extends GroupFeed> type, PathMetadata metadata, PathInits inits) {
        super(type, metadata, inits);
        this.author = inits.isInitialized("author") ? new NPJ.Crewer.member.QMember(forProperty("author"), inits.get("author")) : null;
        this.chatRoom = inits.isInitialized("chatRoom") ? new NPJ.Crewer.chat.chatroom.QChatRoom(forProperty("chatRoom")) : null;
    }

}

