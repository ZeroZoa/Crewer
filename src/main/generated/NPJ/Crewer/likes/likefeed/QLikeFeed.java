package NPJ.Crewer.likes.likefeed;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;
import com.querydsl.core.types.dsl.PathInits;


/**
 * QLikeFeed is a Querydsl query type for LikeFeed
 */
@Generated("com.querydsl.codegen.DefaultEntitySerializer")
public class QLikeFeed extends EntityPathBase<LikeFeed> {

    private static final long serialVersionUID = 1634003010L;

    private static final PathInits INITS = PathInits.DIRECT2;

    public static final QLikeFeed likeFeed = new QLikeFeed("likeFeed");

    public final DateTimePath<java.time.Instant> createdAt = createDateTime("createdAt", java.time.Instant.class);

    public final NPJ.Crewer.feeds.feed.QFeed feed;

    public final NumberPath<Long> id = createNumber("id", Long.class);

    public final NPJ.Crewer.member.QMember liker;

    public QLikeFeed(String variable) {
        this(LikeFeed.class, forVariable(variable), INITS);
    }

    public QLikeFeed(Path<? extends LikeFeed> path) {
        this(path.getType(), path.getMetadata(), PathInits.getFor(path.getMetadata(), INITS));
    }

    public QLikeFeed(PathMetadata metadata) {
        this(metadata, PathInits.getFor(metadata, INITS));
    }

    public QLikeFeed(PathMetadata metadata, PathInits inits) {
        this(LikeFeed.class, metadata, inits);
    }

    public QLikeFeed(Class<? extends LikeFeed> type, PathMetadata metadata, PathInits inits) {
        super(type, metadata, inits);
        this.feed = inits.isInitialized("feed") ? new NPJ.Crewer.feeds.feed.QFeed(forProperty("feed"), inits.get("feed")) : null;
        this.liker = inits.isInitialized("liker") ? new NPJ.Crewer.member.QMember(forProperty("liker"), inits.get("liker")) : null;
    }

}

