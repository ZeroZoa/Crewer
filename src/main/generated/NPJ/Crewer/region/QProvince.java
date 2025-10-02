package NPJ.Crewer.region;

import static com.querydsl.core.types.PathMetadataFactory.*;

import com.querydsl.core.types.dsl.*;

import com.querydsl.core.types.PathMetadata;
import javax.annotation.processing.Generated;
import com.querydsl.core.types.Path;


/**
 * QProvince is a Querydsl query type for Province
 */
@Generated("com.querydsl.codegen.DefaultEntitySerializer")
public class QProvince extends EntityPathBase<Province> {

    private static final long serialVersionUID = 252462832L;

    public static final QProvince province = new QProvince("province");

    public final DateTimePath<java.time.Instant> createdAt = createDateTime("createdAt", java.time.Instant.class);

    public final StringPath geojsonFilePath = createString("geojsonFilePath");

    public final NumberPath<Double> latitude = createNumber("latitude", Double.class);

    public final StringPath level = createString("level");

    public final NumberPath<Double> longitude = createNumber("longitude", Double.class);

    public final StringPath regionId = createString("regionId");

    public final StringPath regionName = createString("regionName");

    public QProvince(String variable) {
        super(Province.class, forVariable(variable));
    }

    public QProvince(Path<? extends Province> path) {
        super(path.getType(), path.getMetadata());
    }

    public QProvince(PathMetadata metadata) {
        super(Province.class, metadata);
    }

}

