package NPJ.Crewer.feeds.feed;

import NPJ.Crewer.feeds.feed.dto.FeedDetailResponseDTO;
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
import java.util.Optional;

@Repository
public interface FeedRepository extends JpaRepository<Feed, Long> {

    //카테시안 곱 문제를 줄이기 위해 id리스트를 반환 후 id를 기반으로 조회 -------------------

    // 최신순
    @Query("SELECT f.id FROM Feed f ORDER BY f.createdAt DESC")
    Page<Long> findFeedIds(Pageable pageable);

    // 좋아요순(최근 일주일)으로  정렬된 GroupFeed의 ID를 페이징하여 조회
    @Query("SELECT f.id FROM Feed f LEFT JOIN f.likes l " +
            "WHERE f.createdAt >= :sevenDaysAgo " +
            "GROUP BY f.id " +
            "ORDER BY COUNT(l) DESC, f.createdAt DESC")
    Page<Long> findHotFeedIds(@Param("sevenDaysAgo") Instant sevenDaysAgo, Pageable pageable);


    //조회된 id를 기준으로 join하여 N+1문제를 해결 -------------------

    //id만 조회한 후 상세 정보(좋아요, 댓글 수)를 조회
    @Query("SELECT new NPJ.Crewer.feeds.feed.dto.FeedResponseDTO(" +
            "    f.id, f.title, f.content, f.author.nickname, f.author.username, f.createdAt, " +
            "    (SELECT COUNT(l) FROM LikeFeed l WHERE l.feed = f), " +
            "    (SELECT COUNT(c) FROM FeedComment c WHERE c.feed = f)" +
            ") " +
            "FROM Feed f " +
            "WHERE f.id IN :ids")
    List<FeedResponseDTO> findFeedInfoByIds(@Param("ids") List<Long> ids);

    // 작성자 기준 DTO 리스트 조회
    @Query("SELECT new NPJ.Crewer.feeds.feed.dto.FeedResponseDTO(" +
            "    f.id, f.title, f.content, f.author.nickname, f.author.username, f.createdAt, " +
            "    (SELECT COUNT(l) FROM LikeFeed l WHERE l.feed = f), " +
            "    (SELECT COUNT(c) FROM FeedComment c WHERE c.feed = f)" +
            ") " +
            "FROM Feed f WHERE f.author = :author ORDER BY f.createdAt DESC")
    List<FeedResponseDTO> findByAuthor(@Param("author") Member author);


    //id를 통해 Feed_Detail 조회
    @Query("SELECT DISTINCT f FROM Feed f " +
            "LEFT JOIN FETCH f.comments " +
            "WHERE f.id = :feedId")
    Optional<Feed> findByIdForFeedDetail(@Param("feedId") Long feedId);
}