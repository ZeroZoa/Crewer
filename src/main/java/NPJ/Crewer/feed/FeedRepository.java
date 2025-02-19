package NPJ.Crewer.feed;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;


import java.util.List;

public interface FeedRepository extends JpaRepository<Feed, Long> {
    List<Feed> findByAuthorUsernameOrderByCreatedAtDesc(String username);
}
