package NPJ.Crewer.region;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;
import com.querydsl.core.types.dsl.PathInits;


/**
 * QMemberActivityRegion is a Querydsl query type for MemberActivityRegion
 */
@Generated("com.querydsl.codegen.DefaultEntitySerializer")
public class QMemberActivityRegion extends EntityPathBase<MemberActivityRegion> {

    private static final long serialVersionUID = -299992099L;

    private static final PathInits INITS = PathInits.DIRECT2;

    public static final QMemberActivityRegion memberActivityRegion = new QMemberActivityRegion("memberActivityRegion");

    public final DateTimePath<java.time.Instant> createdAt = createDateTime("createdAt", java.time.Instant.class);

    public final QDistrict district;

    public final NumberPath<Long> id = createNumber("id", Long.class);

    public final NPJ.Crewer.member.QMember member;

    public final DateTimePath<java.time.Instant> updatedAt = createDateTime("updatedAt", java.time.Instant.class);

    public QMemberActivityRegion(String variable) {
        this(MemberActivityRegion.class, forVariable(variable), INITS);
    }

    public QMemberActivityRegion(Path<? extends MemberActivityRegion> path) {
        this(path.getType(), path.getMetadata(), PathInits.getFor(path.getMetadata(), INITS));
    }

    public QMemberActivityRegion(PathMetadata metadata) {
        this(metadata, PathInits.getFor(metadata, INITS));
    }

    public QMemberActivityRegion(PathMetadata metadata, PathInits inits) {
        this(MemberActivityRegion.class, metadata, inits);
    }

    public QMemberActivityRegion(Class<? extends MemberActivityRegion> type, PathMetadata metadata, PathInits inits) {
        super(type, metadata, inits);
        this.district = inits.isInitialized("district") ? new QDistrict(forProperty("district"), inits.get("district")) : null;
        this.member = inits.isInitialized("member") ? new NPJ.Crewer.member.QMember(forProperty("member"), inits.get("member")) : null;
    }

}

