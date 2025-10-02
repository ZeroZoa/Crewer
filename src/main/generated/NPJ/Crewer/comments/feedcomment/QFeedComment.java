package NPJ.Crewer.comments.feedcomment;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;
import com.querydsl.core.types.dsl.PathInits;


/**
 * QFeedComment is a Querydsl query type for FeedComment
 */
@Generated("com.querydsl.codegen.DefaultEntitySerializer")
public class QFeedComment extends EntityPathBase<FeedComment> {

    private static final long serialVersionUID = 1448710196L;

    private static final PathInits INITS = PathInits.DIRECT2;

    public static final QFeedComment feedComment = new QFeedComment("feedComment");

    public final NPJ.Crewer.member.QMember author;

    public final StringPath content = createString("content");

    public final DateTimePath<java.time.Instant> createdAt = createDateTime("createdAt", java.time.Instant.class);

    public final NPJ.Crewer.feeds.feed.QFeed feed;

    public final NumberPath<Long> id = createNumber("id", Long.class);

    public QFeedComment(String variable) {
        this(FeedComment.class, forVariable(variable), INITS);
    }

    public QFeedComment(Path<? extends FeedComment> path) {
        this(path.getType(), path.getMetadata(), PathInits.getFor(path.getMetadata(), INITS));
    }

    public QFeedComment(PathMetadata metadata) {
        this(metadata, PathInits.getFor(metadata, INITS));
    }

    public QFeedComment(PathMetadata metadata, PathInits inits) {
        this(FeedComment.class, metadata, inits);
    }

    public QFeedComment(Class<? extends FeedComment> type, PathMetadata metadata, PathInits inits) {
        super(type, metadata, inits);
        this.author = inits.isInitialized("author") ? new NPJ.Crewer.member.QMember(forProperty("author"), inits.get("author")) : null;
        this.feed = inits.isInitialized("feed") ? new NPJ.Crewer.feeds.feed.QFeed(forProperty("feed"), inits.get("feed")) : null;
    }

}

