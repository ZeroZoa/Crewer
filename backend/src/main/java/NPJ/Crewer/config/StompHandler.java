package NPJ.Crewer.config;

import NPJ.Crewer.config.JWT.JwtTokenProvider;
import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class StompHandler implements ChannelInterceptor {

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(message);

        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            String authHeader = accessor.getFirstNativeHeader("Authorization");
            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                String token = authHeader.substring(7);
                if (jwtTokenProvider.validateToken(token)) {
                    Member member = jwtTokenProvider.getMemberFromToken(token);
                    accessor.getSessionAttributes().put("memberId", member.getId());
                } else {
                    throw new IllegalArgumentException("JWT가 유효하지 않습니다.");
                }
            } else {
                throw new IllegalArgumentException("Authorization 헤더가 없습니다.");
            }
        }
        return message;
    }
}
