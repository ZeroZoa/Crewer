package NPJ.Crewer.feed.groupFeed;

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

    //성능을 위해 페이지 단위로 페이지를 갖고옴
    Page<GroupFeed> findAll(Pageable pageable);

    //작성자 아이디를 통해 해당 작성자가 작성한 GroupFeed 최신순으로 찾기
    List<GroupFeed> findByAuthorOrderByCreatedAtDesc(Member author);

    //해당 GroupFeed의 좋아요 개수 조회
    @Query("SELECT COUNT(l) FROM LikeGroupFeed l WHERE l.groupFeed.id = :groupFeedId")
    int countLikesByGroupFeedId(@Param("groupFeedId") Long groupFeedId);


    //해당 GroupFeed의 댓글 개수 조회
    @Query("SELECT COUNT(c) FROM GroupFeedComment c WHERE c.groupFeed.id = :groupFeedId")
    int countCommentsByGroupFeedId(@Param("groupFeedId") Long groupFeedId);
}
