package NPJ.Crewer.running.dto.response;

import java.time.Instant;

public interface RankingResponse {
    Long getRecordId();
    Long getRunnerId();
    Double getTotalDistance();
    Integer getTotalSeconds();
    Instant getCreatedAt();
    String getDistanceCategory();
    Integer getRanking();
}
