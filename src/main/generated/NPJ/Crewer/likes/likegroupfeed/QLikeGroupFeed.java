package NPJ.Crewer.likes.likegroupfeed;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;
import com.querydsl.core.types.dsl.PathInits;


/**
 * QLikeGroupFeed is a Querydsl query type for LikeGroupFeed
 */
@Generated("com.querydsl.codegen.DefaultEntitySerializer")
public class QLikeGroupFeed extends EntityPathBase<LikeGroupFeed> {

    private static final long serialVersionUID = -397434126L;

    private static final PathInits INITS = PathInits.DIRECT2;

    public static final QLikeGroupFeed likeGroupFeed = new QLikeGroupFeed("likeGroupFeed");

    public final DateTimePath<java.time.Instant> createdAt = createDateTime("createdAt", java.time.Instant.class);

    public final NPJ.Crewer.feeds.groupfeed.QGroupFeed groupFeed;

    public final NumberPath<Long> id = createNumber("id", Long.class);

    public final NPJ.Crewer.member.QMember liker;

    public QLikeGroupFeed(String variable) {
        this(LikeGroupFeed.class, forVariable(variable), INITS);
    }

    public QLikeGroupFeed(Path<? extends LikeGroupFeed> path) {
        this(path.getType(), path.getMetadata(), PathInits.getFor(path.getMetadata(), INITS));
    }

    public QLikeGroupFeed(PathMetadata metadata) {
        this(metadata, PathInits.getFor(metadata, INITS));
    }

    public QLikeGroupFeed(PathMetadata metadata, PathInits inits) {
        this(LikeGroupFeed.class, metadata, inits);
    }

    public QLikeGroupFeed(Class<? extends LikeGroupFeed> type, PathMetadata metadata, PathInits inits) {
        super(type, metadata, inits);
        this.groupFeed = inits.isInitialized("groupFeed") ? new NPJ.Crewer.feeds.groupfeed.QGroupFeed(forProperty("groupFeed"), inits.get("groupFeed")) : null;
        this.liker = inits.isInitialized("liker") ? new NPJ.Crewer.member.QMember(forProperty("liker"), inits.get("liker")) : null;
    }

}

