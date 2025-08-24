package NPJ.Crewer.running.dto.response;

import java.time.Instant;

public interface RankingResponse {
    Long getRecordId();
    Long getRunnerId();
    String getRunnerNickname();
    Double getTotalDistance();
    Integer getTotalSeconds();
    Instant getCreatedAt();
    String getDistanceCategory();
    Integer getRanking();
}
