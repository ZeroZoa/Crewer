package NPJ.Crewer.email;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender javaMailSender;

    @Value("${spring.mail.username}")
    private String senderEmail;

    public void sendVerificationEmail(String email, String verificationCode) {
        try {
            MimeMessage message = createVerificationMessage(email, verificationCode);
            javaMailSender.send(message);
        } catch (MessagingException e) {
            log.error("메일 발송 실패: {}", email, e);
            throw new RuntimeException("메일 발송에 실패했습니다.", e);
        }
    }

    private MimeMessage createVerificationMessage(String email, String authCode) throws MessagingException {
        MimeMessage message = javaMailSender.createMimeMessage();

        message.setFrom(senderEmail);
        message.setRecipients(MimeMessage.RecipientType.TO, email);
        message.setSubject("[Crewer] 이메일 인증 코드 안내");
        String body = "<h3>[Crewer] 요청하신 인증 코드입니다.</h3>"
                + "<h1>" + authCode + "</h1>"
                + "<h3>코드를 입력하여 인증을 완료해주세요.</h3>";
        message.setText(body, "UTF-8", "html");

        return message;
    }
}