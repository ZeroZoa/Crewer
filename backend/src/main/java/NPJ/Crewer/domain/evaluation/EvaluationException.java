package NPJ.Crewer.domain.evaluation;

import NPJ.Crewer.global.exception.BusinessException;

public class EvaluationException extends BusinessException {
    public EvaluationException(String message) {
        super(message);
    }
    
    public EvaluationException(String message, Throwable cause) {
        super(message, cause);
    }
}

