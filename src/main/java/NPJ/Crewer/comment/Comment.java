package NPJ.Crewer.comment;

import NPJ.Crewer.feed.Feed;
import NPJ.Crewer.member.Member;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class) // 생성/수정일 자동 관리
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Comment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content; // 댓글 내용

    @ManyToOne(fetch = FetchType.LAZY) // 하나의 Feed에 여러 개의 Comment
    @JoinColumn(name = "feed_id", nullable = false)
    @JsonIgnoreProperties("comments") //Feed가 가진 comments 리스트를 무시하여 순환참조 방지
    private Feed feed;

    @ManyToOne(fetch = FetchType.LAZY) // 하나의 Member가 여러 개의 Comment 작성 가능
    @JoinColumn(name = "member_id", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "feeds", "comments"}) //Hibernate의 Lazy 로딩 프록시 문제 방지
    private Member author;


    //아래는 생성일과 수정일을 Spring에서 자동으로 관리
    @CreatedDate
    private LocalDateTime createdAt; // 생성일 자동 기록

    @LastModifiedDate
    private LocalDateTime updatedAt; // 수정일 자동 기록
}