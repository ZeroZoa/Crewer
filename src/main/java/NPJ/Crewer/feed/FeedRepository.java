package NPJ.Crewer.feed;

import NPJ.Crewer.member.Member;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FeedRepository extends JpaRepository<Feed, Long> {

    //작성자 아이디를 통해 해당 작성자가 작성한 글 최신순으로 찾기
    List<Feed> findByAuthorOrderByCreatedAtDesc(Member author);

    //성능을 위해 페이지 단위로 페이지를 갖고옴
    Page<Feed> findAll(Pageable pageable);

    // ✅ 해당 피드의 좋아요 개수 조회
    @Query("SELECT COUNT(l) FROM LikeFeed l WHERE l.feed.id = :feedId")
    int countLikesByFeedId(@Param("feedId") Long feedId);

    // ✅ 해당 피드의 댓글 개수 조회
    @Query("SELECT COUNT(c) FROM Comment c WHERE c.feed.id = :feedId")
    int countCommentsByFeedId(@Param("feedId") Long feedId);
}
