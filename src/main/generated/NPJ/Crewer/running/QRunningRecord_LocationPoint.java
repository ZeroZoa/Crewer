package NPJ.Crewer.running;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;


/**
 * QRunningRecord_LocationPoint is a Querydsl query type for LocationPoint
 */
@Generated("com.querydsl.codegen.DefaultEmbeddableSerializer")
public class QRunningRecord_LocationPoint extends BeanPath<RunningRecord.LocationPoint> {

    private static final long serialVersionUID = -1396281516L;

    public static final QRunningRecord_LocationPoint locationPoint = new QRunningRecord_LocationPoint("locationPoint");

    public final NumberPath<Double> latitude = createNumber("latitude", Double.class);

    public final NumberPath<Double> longitude = createNumber("longitude", Double.class);

    public QRunningRecord_LocationPoint(String variable) {
        super(RunningRecord.LocationPoint.class, forVariable(variable));
    }

    public QRunningRecord_LocationPoint(Path<? extends RunningRecord.LocationPoint> path) {
        super(path.getType(), path.getMetadata());
    }

    public QRunningRecord_LocationPoint(PathMetadata metadata) {
        super(RunningRecord.LocationPoint.class, metadata);
    }

}

