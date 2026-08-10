package NPJ.Crewer.notification;

public class NotificationException extends RuntimeException {
    public NotificationException(String message) {
        super(message);
    }
    
    public NotificationException(String message, Throwable cause) {
        super(message, cause);
    }
}

