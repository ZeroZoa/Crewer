package NPJ.Crewer.feeds.groupfeed;

import NPJ.Crewer.feeds.feed.Feed;
import NPJ.Crewer.member.Member;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GroupFeedRepository extends JpaRepository<GroupFeed, Long> {

    // 페이지 단위 + 최신순 정렬해서 가져옴
    Page<GroupFeed> findAllByOrderByCreatedAtDesc(Pageable pageable);

    //좋아요 순 + 최신순 정렬해서 Feed로 가져옴
    @Query(
            value = "SELECT g.* " +
                    "FROM group_feed g LEFT JOIN like_group_feed l ON g.id = l.group_feed_id " +
                    "GROUP BY g.id " +
                    "ORDER BY COUNT(l.id) DESC, created_at DESC",
            countQuery = "SELECT COUNT(*) FROM group_feed",
            nativeQuery = true
    )
    Page<GroupFeed> findFeedsOrderByLikes(Pageable pageable);

//    //성능을 위해 페이지 단위로 페이지를 갖고옴
//    Page<GroupFeed> findAll(Pageable pageable);

    //작성자 아이디를 통해 해당 작성자가 작성한 GroupFeed 최신순으로 찾기
    List<GroupFeed> findByAuthorOrderByCreatedAtDesc(Member author);

    //해당 GroupFeed의 좋아요 개수 조회
    @Query("SELECT COUNT(l) FROM LikeGroupFeed l WHERE l.groupFeed.id = :groupFeedId")
    int countLikesByGroupFeedId(@Param("groupFeedId") Long groupFeedId);


    //해당 GroupFeed의 댓글 개수 조회
    @Query("SELECT COUNT(c) FROM GroupFeedComment c WHERE c.groupFeed.id = :groupFeedId")
    int countCommentsByGroupFeedId(@Param("groupFeedId") Long groupFeedId);
}
