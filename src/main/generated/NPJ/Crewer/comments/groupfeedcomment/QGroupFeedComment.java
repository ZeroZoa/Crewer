package NPJ.Crewer.comments.groupfeedcomment;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;
import com.querydsl.core.types.dsl.PathInits;


/**
 * QGroupFeedComment is a Querydsl query type for GroupFeedComment
 */
@Generated("com.querydsl.codegen.DefaultEntitySerializer")
public class QGroupFeedComment extends EntityPathBase<GroupFeedComment> {

    private static final long serialVersionUID = -1727883986L;

    private static final PathInits INITS = PathInits.DIRECT2;

    public static final QGroupFeedComment groupFeedComment = new QGroupFeedComment("groupFeedComment");

    public final NPJ.Crewer.member.QMember author;

    public final StringPath content = createString("content");

    public final DateTimePath<java.time.Instant> createdAt = createDateTime("createdAt", java.time.Instant.class);

    public final NPJ.Crewer.feeds.groupfeed.QGroupFeed groupFeed;

    public final NumberPath<Long> id = createNumber("id", Long.class);

    public QGroupFeedComment(String variable) {
        this(GroupFeedComment.class, forVariable(variable), INITS);
    }

    public QGroupFeedComment(Path<? extends GroupFeedComment> path) {
        this(path.getType(), path.getMetadata(), PathInits.getFor(path.getMetadata(), INITS));
    }

    public QGroupFeedComment(PathMetadata metadata) {
        this(metadata, PathInits.getFor(metadata, INITS));
    }

    public QGroupFeedComment(PathMetadata metadata, PathInits inits) {
        this(GroupFeedComment.class, metadata, inits);
    }

    public QGroupFeedComment(Class<? extends GroupFeedComment> type, PathMetadata metadata, PathInits inits) {
        super(type, metadata, inits);
        this.author = inits.isInitialized("author") ? new NPJ.Crewer.member.QMember(forProperty("author"), inits.get("author")) : null;
        this.groupFeed = inits.isInitialized("groupFeed") ? new NPJ.Crewer.feeds.groupfeed.QGroupFeed(forProperty("groupFeed"), inits.get("groupFeed")) : null;
    }

}

