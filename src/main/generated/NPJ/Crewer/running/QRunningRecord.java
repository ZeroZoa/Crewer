package NPJ.Crewer.running;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;
import com.querydsl.core.types.dsl.PathInits;


/**
 * QRunningRecord is a Querydsl query type for RunningRecord
 */
@Generated("com.querydsl.codegen.DefaultEntitySerializer")
public class QRunningRecord extends EntityPathBase<RunningRecord> {

    private static final long serialVersionUID = 973258311L;

    private static final PathInits INITS = PathInits.DIRECT2;

    public static final QRunningRecord runningRecord = new QRunningRecord("runningRecord");

    public final DateTimePath<java.time.Instant> createdAt = createDateTime("createdAt", java.time.Instant.class);

    public final NumberPath<Long> id = createNumber("id", Long.class);

    public final ListPath<RunningRecord.LocationPoint, QRunningRecord_LocationPoint> path = this.<RunningRecord.LocationPoint, QRunningRecord_LocationPoint>createList("path", RunningRecord.LocationPoint.class, QRunningRecord_LocationPoint.class, PathInits.DIRECT2);

    public final NPJ.Crewer.member.QMember runner;

    public final NumberPath<Double> totalDistance = createNumber("totalDistance", Double.class);

    public final NumberPath<Integer> totalSeconds = createNumber("totalSeconds", Integer.class);

    public QRunningRecord(String variable) {
        this(RunningRecord.class, forVariable(variable), INITS);
    }

    public QRunningRecord(Path<? extends RunningRecord> path) {
        this(path.getType(), path.getMetadata(), PathInits.getFor(path.getMetadata(), INITS));
    }

    public QRunningRecord(PathMetadata metadata) {
        this(metadata, PathInits.getFor(metadata, INITS));
    }

    public QRunningRecord(PathMetadata metadata, PathInits inits) {
        this(RunningRecord.class, metadata, inits);
    }

    public QRunningRecord(Class<? extends RunningRecord> type, PathMetadata metadata, PathInits inits) {
        super(type, metadata, inits);
        this.runner = inits.isInitialized("runner") ? new NPJ.Crewer.member.QMember(forProperty("runner"), inits.get("runner")) : null;
    }

}

