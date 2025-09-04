package NPJ.Crewer.feeds.feed;

import NPJ.Crewer.feeds.feed.dto.FeedResponseDTO;
import NPJ.Crewer.member.Member;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface FeedRepository extends JpaRepository<Feed, Long> {
    // 페이지 단위 + 최신순 정렬해서 가져옴
    Page<Feed> findAllByOrderByCreatedAtDesc(Pageable pageable);

    @Query("SELECT new NPJ.Crewer.feeds.feed.dto.FeedResponseDTO(" +
            "    f.id, " +
            "    f.title, " +
            "    f.content, " +
            "    f.author.nickname, " +
            "    f.author.username, " +
            "    f.createdAt, " +
            "    CAST(COUNT(DISTINCT l) AS int), " +
            "    CAST(COUNT(DISTINCT c) AS int)" +
            ") " +
            "FROM Feed f " +
            "LEFT JOIN f.likes l " +
            "LEFT JOIN f.comments c " +
            "WHERE f.createdAt >= :sevenDaysAgo " +
            "GROUP BY f.id, f.author.nickname, f.author.username " +
            "ORDER BY COUNT(DISTINCT l) DESC")
    Page<FeedResponseDTO> findHotFeedsDTO(@Param("sevenDaysAgo") Instant sevenDaysAgo, Pageable pageable);

    //좋아요 순 + 최신순 정렬해서 Feed로 가져옴
    @Query(
            value = "SELECT f.* " +
                    "FROM feed f LEFT JOIN like_feed l ON f.id = l.feed_id " +
                    "GROUP BY f.id " +
                    "ORDER BY COUNT(l.id) DESC, created_at DESC",
            countQuery = "SELECT COUNT(*) FROM feed",
            nativeQuery = true
    )
    Page<Feed> findFeedsOrderByLikes(Pageable pageable);

    //작성자 아이디를 통해 해당 작성자가 작성한 Feed 최신순으로 찾기
    List<Feed> findByAuthorOrderByCreatedAtDesc(Member author);

    //해당 Feed의 좋아요 개수 조회
    @Query("SELECT COUNT(l) FROM LikeFeed l WHERE l.feed.id = :feedId")
    int countLikesByFeedId(@Param("feedId") Long feedId);

    //해당 Feed의 댓글 개수 조회
    @Query("SELECT COUNT(c) FROM FeedComment c WHERE c.feed.id = :feedId")
    int countCommentsByFeedId(@Param("feedId") Long feedId);
}
