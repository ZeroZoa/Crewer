package NPJ.Crewer.running.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Instant;

@Getter
@AllArgsConstructor
public class RankingInfo {
    private Long recordId;
    private Long runnerId;
    private String runnerNickname;
    private double totalDistance;
    private int totalSeconds;
    private Instant createdAt;
    private String distanceCategory;
    private int ranking;

    // RankingResponse를 DTO RankingInfo로 변환하기 위한 정적 팩토리 메서드
    public static RankingInfo from(RankingResponse rankingResponse) {
        return new RankingInfo(
                rankingResponse.getRecordId(),
                rankingResponse.getRunnerId(),
                rankingResponse.getRunnerNickname(),
                rankingResponse.getTotalDistance(),
                rankingResponse.getTotalSeconds(),
                rankingResponse.getCreatedAt(),
                rankingResponse.getDistanceCategory(),
                rankingResponse.getRanking()
        );
    }
}
