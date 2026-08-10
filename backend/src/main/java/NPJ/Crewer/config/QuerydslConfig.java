package NPJ.Crewer.config;
import com.querydsl.jpa.impl.JPAQueryFactory;
import jakarta.persistence.EntityManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
@Configuration
public class QuerydslConfig {
    private final EntityManager em;

    // 스프링이 JPA를 위해 만든 EntityManager를 주입받음
    public QuerydslConfig(EntityManager em) {
        this.em = em;
    }

    // ★ JPAQueryFactory 객체를 스프링 빈으로 등록
    // 이 객체가 QueryDSL 쿼리를 실행하는 핵심 도구입니다.
    @Bean
    public JPAQueryFactory jpaQueryFactory() {
        return new JPAQueryFactory(em); // EntityManager를 사용해 팩토리를 생성
    }
}
