package NPJ.Crewer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableJpaAuditing
@EnableScheduling
public class CrewerApplication {

	public static void main(String[] args) {
		//배포를 위해 doenv 주석처리
		//Dotenv dotenv = Dotenv.configure().load();
		//dotenv.entries().forEach(entry -> System.setProperty(entry.getKey(), entry.getValue()));

		SpringApplication.run(CrewerApplication.class, args);
	}

}
