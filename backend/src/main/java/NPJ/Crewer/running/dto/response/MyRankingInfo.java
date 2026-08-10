package NPJ.Crewer.running.dto.response;

import lombok.Getter;

@Getter
public class MyRankingInfo {
    private final String distanceCategory;
    private final int myRank;
    private final int totalRankedCount;
    private final double percentile;
    private final RankingInfo myRecord;

    public MyRankingInfo(String distanceCategory, int myRank, int totalRankedCount, RankingInfo myRecord) {
        this.distanceCategory = distanceCategory;
        this.myRank = myRank;
        this.totalRankedCount = totalRankedCount;
        this.percentile = (totalRankedCount > 0) ? ((double) myRank / totalRankedCount * 100) : 0;
        this.myRecord = myRecord;
    }
}
