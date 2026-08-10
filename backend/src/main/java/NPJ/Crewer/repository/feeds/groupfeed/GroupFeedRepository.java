package NPJ.Crewer.feeds.groupfeed;

import NPJ.Crewer.feeds.groupfeed.dto.GroupFeedResponseDTO;
import NPJ.Crewer.member.Member;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface GroupFeedRepository extends JpaRepository<GroupFeed, Long> {

    //카테시안 곱 문제를 줄이기 위해 id리스트를 반환 후 id를 기반으로 조회 -------------------

    //최신순으로 정렬된 GroupFeed의 ID를 페이징하여 조회
    @Query("SELECT gf.id FROM GroupFeed gf ORDER BY gf.createdAt DESC")
    Page<Long> findGroupFeedIds(Pageable pageable);


    //좋아요순(최근 일주일)으로 정렬된 GroupFeed의 ID를 페이징하여 조회
    @Query(value = "SELECT gf.id FROM GroupFeed gf LEFT JOIN gf.likes l " +
            "WHERE gf.createdAt >= :sevenDaysAgo " +
            "GROUP BY gf.id " +
            "ORDER BY COUNT(l) DESC, gf.createdAt DESC")
    Page<Long> findHotGroupFeedIds(@Param("sevenDaysAgo")Instant sevenDaysAgo, Pageable pageable);


    //마감 임박 또는 인기 있는 GroupFeed의 ID를 페이징하여 조회
    @Query("SELECT gf.id " +
            "FROM GroupFeed gf JOIN gf.chatRoom cr " +
            "WHERE gf.deadline > CURRENT_TIMESTAMP AND " +
            "((cr.currentParticipants > cr.maxParticipants * 0.2) OR (gf.deadline <= :sixHoursAgo)) " +
            "ORDER BY gf.createdAt DESC")
    Page<Long> findAlmostFullGroupFeedIds(@Param("sixHoursAgo") Instant sixHoursAgo, Pageable pageable);

    //검색 기능을 위해 title, content, nickname을 기준으로 id 조회
    @Query("SELECT gf.id FROM GroupFeed gf JOIN gf.author a " +
            "WHERE a.nickname LIKE %:keyword% " +
            "OR gf.title LIKE %:keyword% " +
            "OR gf.content LIKE %:keyword% " +
            "ORDER BY gf.createdAt DESC")
    Page<Long> findIdsByKeyword(@Param("keyword") String keyword, Pageable pageable);

    //위의 매서드를 통해 조회된 id를 기준으로 join하여 N+1문제를 해결 -------------------


    @Query("SELECT new NPJ.Crewer.feeds.groupfeed.dto.GroupFeedResponseDTO(" +
            "    gf.id, gf.title, gf.content, gf.author.nickname, gf.author.username, gf.author.profile.avatarUrl, " +
            "    gf.meetingPlace, gf.latitude, gf.longitude, gf.deadline, gf.chatRoom.id, gf.chatRoom.currentParticipants, gf.chatRoom.maxParticipants, gf.createdAt, " +
            "    (SELECT COUNT(l) FROM LikeGroupFeed l WHERE l.groupFeed = gf), " +
            "    (SELECT COUNT(c) FROM GroupFeedComment c WHERE c.groupFeed = gf)" +
            ") " +
            "FROM GroupFeed gf LEFT JOIN gf.chatRoom cr " +
            "WHERE gf.id IN :ids")
    List<GroupFeedResponseDTO> findGroupFeedInfoByIds(@Param("ids") List<Long> ids);


    // --- 기타 조회 ---

    //작성자 기준으로 DTO 리스트 조회
    @Query("SELECT new NPJ.Crewer.feeds.groupfeed.dto.GroupFeedResponseDTO(" +
            "    gf.id, gf.title, gf.content, gf.author.nickname, gf.author.username, gf.author.profile.avatarUrl, " +
            "    gf.meetingPlace, gf.latitude, gf.longitude, gf.deadline, gf.chatRoom.id, gf.chatRoom.currentParticipants, gf.chatRoom.maxParticipants, gf.createdAt, " +
            "    (SELECT COUNT(l) FROM LikeGroupFeed l WHERE l.groupFeed = gf), " +
            "    (SELECT COUNT(c) FROM GroupFeedComment c WHERE c.groupFeed = gf)" +
            ") " +
            "FROM GroupFeed gf JOIN gf.chatRoom cr " +
            "WHERE gf.author = :author ORDER BY gf.createdAt DESC")
    List<GroupFeedResponseDTO> findByAuthor(@Param("author") Member author);

    //ID를 통해 GroupFeed 상세 정보 조회 (댓글은 JOIN FETCH, 좋아요는 @BatchSize로 효율적 조회)
    @Query("SELECT DISTINCT gf FROM GroupFeed gf " +
            "LEFT JOIN FETCH gf.comments " +
            "WHERE gf.id = :groupFeedId")
    Optional<GroupFeed> findByIdForGroupFeedDetail(@Param("groupFeedId") Long groupFeedId);

    //채팅방 ID로 GroupFeed 조회
    Optional<GroupFeed> findByChatRoomId(java.util.UUID chatRoomId);
    
    //채팅방 ID로 GroupFeed 기본 정보만 조회 (Projection) - 순환참조 방지
    @Query("SELECT gf.id, gf.title, gf.status, gf.author.id FROM GroupFeed gf WHERE gf.chatRoom.id = :chatRoomId")
    Optional<Object[]> findBasicInfoByChatRoomId(@Param("chatRoomId") java.util.UUID chatRoomId);
    
    //채팅방 ID로 GroupFeed 작성자 ID만 조회 (순환참조 완전 방지)
    @Query("SELECT gf.author.id FROM GroupFeed gf WHERE gf.chatRoom.id = :chatRoomId")
    Optional<Long> findAuthorIdByChatRoomId(@Param("chatRoomId") java.util.UUID chatRoomId);
    
    //GroupFeed ID로 제목만 조회 (순환참조 완전 방지)
    @Query("SELECT gf.title FROM GroupFeed gf WHERE gf.id = :groupFeedId")
    Optional<String> findTitleById(@Param("groupFeedId") Long groupFeedId);
    
    //채팅방 ID로 GroupFeed ID만 조회 (가장 안전)
    @Query("SELECT gf.id FROM GroupFeed gf WHERE gf.chatRoom.id = :chatRoomId")
    Optional<Long> findIdByChatRoomId(@Param("chatRoomId") java.util.UUID chatRoomId);
    
    //GroupFeed 상태를 COMPLETED로 업데이트 (엔티티 조회 없이)
    @Modifying
    @Query("UPDATE GroupFeed gf SET gf.status = 'COMPLETED' WHERE gf.id = :groupFeedId")
    void updateStatusToCompleted(@Param("groupFeedId") Long groupFeedId);
    
    //GroupFeed 상태 조회 (중복 종료 방지용)
    @Query("SELECT gf.status FROM GroupFeed gf WHERE gf.id = :groupFeedId")
    Optional<GroupFeedStatus> findStatusById(@Param("groupFeedId") Long groupFeedId);
}
