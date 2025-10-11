package NPJ.Crewer.evaluation;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;
import com.querydsl.core.types.dsl.PathInits;


/**
 * QEvaluation is a Querydsl query type for Evaluation
 */
@Generated("com.querydsl.codegen.DefaultEntitySerializer")
public class QEvaluation extends EntityPathBase<Evaluation> {

    private static final long serialVersionUID = 1879323316L;

    private static final PathInits INITS = PathInits.DIRECT2;

    public static final QEvaluation evaluation = new QEvaluation("evaluation");

    public final DateTimePath<java.time.Instant> createdAt = createDateTime("createdAt", java.time.Instant.class);

    public final NPJ.Crewer.member.QMember evaluated;

    public final NPJ.Crewer.member.QMember evaluator;

    public final NPJ.Crewer.feeds.groupfeed.QGroupFeed groupFeed;

    public final NumberPath<Long> id = createNumber("id", Long.class);

    public final EnumPath<EvaluationType> type = createEnum("type", EvaluationType.class);

    public QEvaluation(String variable) {
        this(Evaluation.class, forVariable(variable), INITS);
    }

    public QEvaluation(Path<? extends Evaluation> path) {
        this(path.getType(), path.getMetadata(), PathInits.getFor(path.getMetadata(), INITS));
    }

    public QEvaluation(PathMetadata metadata) {
        this(metadata, PathInits.getFor(metadata, INITS));
    }

    public QEvaluation(PathMetadata metadata, PathInits inits) {
        this(Evaluation.class, metadata, inits);
    }

    public QEvaluation(Class<? extends Evaluation> type, PathMetadata metadata, PathInits inits) {
        super(type, metadata, inits);
        this.evaluated = inits.isInitialized("evaluated") ? new NPJ.Crewer.member.QMember(forProperty("evaluated"), inits.get("evaluated")) : null;
        this.evaluator = inits.isInitialized("evaluator") ? new NPJ.Crewer.member.QMember(forProperty("evaluator"), inits.get("evaluator")) : null;
        this.groupFeed = inits.isInitialized("groupFeed") ? new NPJ.Crewer.feeds.groupfeed.QGroupFeed(forProperty("groupFeed"), inits.get("groupFeed")) : null;
    }

}

