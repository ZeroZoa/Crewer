package NPJ.Crewer.running.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;
import java.util.Map;

@Getter
@AllArgsConstructor
public class RankingApiResponse {
    private List<MyRankingInfo> myRankings;
    private Map<String, List<RankingInfo>> topRankingsByCategory;
}
