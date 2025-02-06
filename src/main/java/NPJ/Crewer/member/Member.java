package NPJ.Crewer.member;

import NPJ.Crewer.comment.Comment;
import NPJ.Crewer.feed.Feed;
import NPJ.Crewer.like.LikeFeed;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@EntityListeners(AuditingEntityListener.class)
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "feeds", "comments"})
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String username; // 이메일을 로그인 ID로 사용

    @Column(nullable = false)
    private String password; // 암호화된 비밀번호

    @Column(nullable = false, length = 8)
    private String nickname; // 사용자 서비스 내 표시 이름

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private MemberRole role = MemberRole.USER; // 기본값: 일반 사용자

    @OneToMany(mappedBy = "author", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnoreProperties("author") // 🔥 순환참조 방지
    private List<Feed> feeds;

    @OneToMany(mappedBy = "author", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnoreProperties("author") // 🔥 순환참조 방지
    private List<Comment> comments;

    @OneToMany(mappedBy = "member", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnoreProperties({"member"}) // 순환 참조 방지
    private Set<LikeFeed> likes = new HashSet<>();

    //아래는 생성일과 수정일을 Spring에서 자동으로 관리
    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}