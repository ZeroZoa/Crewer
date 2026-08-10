package NPJ.Crewer.domain.follow;

import NPJ.Crewer.global.exception.BusinessException;

public class FollowException extends BusinessException {
    public FollowException(String message) {
        super(message);
    }
    
    public FollowException(String message, Throwable cause) {
        super(message, cause);
    }
} 