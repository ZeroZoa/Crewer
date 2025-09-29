package NPJ.Crewer.feeds.feed;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;
import com.querydsl.core.types.dsl.PathInits;


/**
 * QFeed is a Querydsl query type for Feed
 */
@Generated("com.querydsl.codegen.DefaultEntitySerializer")
public class QFeed extends EntityPathBase<Feed> {

    private static final long serialVersionUID = 1148159451L;

    private static final PathInits INITS = PathInits.DIRECT2;

    public static final QFeed feed = new QFeed("feed");

    public final NPJ.Crewer.member.QMember author;

    public final ListPath<NPJ.Crewer.comments.feedcomment.FeedComment, NPJ.Crewer.comments.feedcomment.QFeedComment> comments = this.<NPJ.Crewer.comments.feedcomment.FeedComment, NPJ.Crewer.comments.feedcomment.QFeedComment>createList("comments", NPJ.Crewer.comments.feedcomment.FeedComment.class, NPJ.Crewer.comments.feedcomment.QFeedComment.class, PathInits.DIRECT2);

    public final StringPath content = createString("content");

    public final DateTimePath<java.time.Instant> createdAt = createDateTime("createdAt", java.time.Instant.class);

    public final NumberPath<Long> id = createNumber("id", Long.class);

    public final ListPath<NPJ.Crewer.likes.likefeed.LikeFeed, NPJ.Crewer.likes.likefeed.QLikeFeed> likes = this.<NPJ.Crewer.likes.likefeed.LikeFeed, NPJ.Crewer.likes.likefeed.QLikeFeed>createList("likes", NPJ.Crewer.likes.likefeed.LikeFeed.class, NPJ.Crewer.likes.likefeed.QLikeFeed.class, PathInits.DIRECT2);

    public final StringPath title = createString("title");

    public final DateTimePath<java.time.Instant> updatedAt = createDateTime("updatedAt", java.time.Instant.class);

    public QFeed(String variable) {
        this(Feed.class, forVariable(variable), INITS);
    }

    public QFeed(Path<? extends Feed> path) {
        this(path.getType(), path.getMetadata(), PathInits.getFor(path.getMetadata(), INITS));
    }

    public QFeed(PathMetadata metadata) {
        this(metadata, PathInits.getFor(metadata, INITS));
    }

    public QFeed(PathMetadata metadata, PathInits inits) {
        this(Feed.class, metadata, inits);
    }

    public QFeed(Class<? extends Feed> type, PathMetadata metadata, PathInits inits) {
        super(type, metadata, inits);
        this.author = inits.isInitialized("author") ? new NPJ.Crewer.member.QMember(forProperty("author"), inits.get("author")) : null;
    }

}

