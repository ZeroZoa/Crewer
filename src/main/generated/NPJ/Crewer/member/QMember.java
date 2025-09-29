package NPJ.Crewer.member;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;
import com.querydsl.core.types.dsl.PathInits;


/**
 * QMember is a Querydsl query type for Member
 */
@Generated("com.querydsl.codegen.DefaultEntitySerializer")
public class QMember extends EntityPathBase<Member> {

    private static final long serialVersionUID = 1143073780L;

    private static final PathInits INITS = PathInits.DIRECT2;

    public static final QMember member = new QMember("member1");

    public final NPJ.Crewer.region.QMemberActivityRegion activityRegion;

    public final DateTimePath<java.time.Instant> createdAt = createDateTime("createdAt", java.time.Instant.class);

    public final DateTimePath<java.time.Instant> emailVerifiedAt = createDateTime("emailVerifiedAt", java.time.Instant.class);

    public final ListPath<NPJ.Crewer.feeds.feed.Feed, NPJ.Crewer.feeds.feed.QFeed> feeds = this.<NPJ.Crewer.feeds.feed.Feed, NPJ.Crewer.feeds.feed.QFeed>createList("feeds", NPJ.Crewer.feeds.feed.Feed.class, NPJ.Crewer.feeds.feed.QFeed.class, PathInits.DIRECT2);

    public final ListPath<NPJ.Crewer.follow.Follow, NPJ.Crewer.follow.QFollow> followers = this.<NPJ.Crewer.follow.Follow, NPJ.Crewer.follow.QFollow>createList("followers", NPJ.Crewer.follow.Follow.class, NPJ.Crewer.follow.QFollow.class, PathInits.DIRECT2);

    public final ListPath<NPJ.Crewer.follow.Follow, NPJ.Crewer.follow.QFollow> following = this.<NPJ.Crewer.follow.Follow, NPJ.Crewer.follow.QFollow>createList("following", NPJ.Crewer.follow.Follow.class, NPJ.Crewer.follow.QFollow.class, PathInits.DIRECT2);

    public final ListPath<NPJ.Crewer.feeds.groupfeed.GroupFeed, NPJ.Crewer.feeds.groupfeed.QGroupFeed> groupFeeds = this.<NPJ.Crewer.feeds.groupfeed.GroupFeed, NPJ.Crewer.feeds.groupfeed.QGroupFeed>createList("groupFeeds", NPJ.Crewer.feeds.groupfeed.GroupFeed.class, NPJ.Crewer.feeds.groupfeed.QGroupFeed.class, PathInits.DIRECT2);

    public final NumberPath<Long> id = createNumber("id", Long.class);

    public final StringPath nickname = createString("nickname");

    public final StringPath password = createString("password");

    public final NPJ.Crewer.profile.QProfile profile;

    public final EnumPath<MemberRole> role = createEnum("role", MemberRole.class);

    public final DateTimePath<java.time.Instant> updatedAt = createDateTime("updatedAt", java.time.Instant.class);

    public final StringPath username = createString("username");

    public QMember(String variable) {
        this(Member.class, forVariable(variable), INITS);
    }

    public QMember(Path<? extends Member> path) {
        this(path.getType(), path.getMetadata(), PathInits.getFor(path.getMetadata(), INITS));
    }

    public QMember(PathMetadata metadata) {
        this(metadata, PathInits.getFor(metadata, INITS));
    }

    public QMember(PathMetadata metadata, PathInits inits) {
        this(Member.class, metadata, inits);
    }

    public QMember(Class<? extends Member> type, PathMetadata metadata, PathInits inits) {
        super(type, metadata, inits);
        this.activityRegion = inits.isInitialized("activityRegion") ? new NPJ.Crewer.region.QMemberActivityRegion(forProperty("activityRegion"), inits.get("activityRegion")) : null;
        this.profile = inits.isInitialized("profile") ? new NPJ.Crewer.profile.QProfile(forProperty("profile"), inits.get("profile")) : null;
    }

}

