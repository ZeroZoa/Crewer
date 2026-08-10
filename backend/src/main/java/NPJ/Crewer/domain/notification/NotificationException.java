package NPJ.Crewer.domain.notification;

import NPJ.Crewer.global.exception.BusinessException;

public class NotificationException extends BusinessException {
    public NotificationException(String message) {
        super(message);
    }
    
    public NotificationException(String message, Throwable cause) {
        super(message, cause);
    }
}

