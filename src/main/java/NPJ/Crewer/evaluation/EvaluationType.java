package NPJ.Crewer.evaluation;

public enum EvaluationType {
    EXCELLENT(2.0),    // 최고예요! (+2도)
    GOOD(1.0),         // 좋았어요 (+1도)
    NEUTRAL(0.0),      // 괜찮았어요 (0도)
    BAD(-1.0),         // 아쉬웠어요 (-1도)
    TERRIBLE(-2.0);    // 최악이었어요 (-2도)
    
    private final double temperatureChange;
    
    EvaluationType(double temperatureChange) {
        this.temperatureChange = temperatureChange;
    }
    
    public double getTemperatureChange() {
        return temperatureChange;
    }
}
