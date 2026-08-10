package NPJ.Crewer.region;

public class RegionNotFoundException extends RuntimeException {
    
    public RegionNotFoundException(String message) {
        super(message);
    }
    
    public RegionNotFoundException(String message, Throwable cause) {
        super(message, cause);
    }
}
