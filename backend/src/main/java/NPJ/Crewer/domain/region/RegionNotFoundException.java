package NPJ.Crewer.domain.region;

import NPJ.Crewer.global.exception.BusinessException;

public class RegionNotFoundException extends BusinessException {
    
    public RegionNotFoundException(String message) {
        super(message);
    }
    
    public RegionNotFoundException(String message, Throwable cause) {
        super(message, cause);
    }
}
