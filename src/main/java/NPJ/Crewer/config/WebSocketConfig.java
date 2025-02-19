package NPJ.Crewer.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableStompBrokerRelay("/topic", "/queue") // RabbitMQ 사용
                .setRelayHost("localhost")
                .setRelayPort(61613)
                .setSystemLogin("guest")
                .setSystemPasscode("guest");
        registry.setApplicationDestinationPrefixes("/app"); // 클라이언트가 메시지를 보낼 경로
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/chat") // 클라이언트가 연결할 WebSocket 엔드포인트
                .setAllowedOrigins("*")
                .withSockJS(); // SockJS 지원
    }
}