package NPJ.Crewer.member;

import NPJ.Crewer.feeds.feed.Feed;
import NPJ.Crewer.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.follow.Follow;
import NPJ.Crewer.profile.Profile;
import NPJ.Crewer.region.MemberActivityRegion;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
@EntityListeners(AuditingEntityListener.class)
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String username;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false, unique = true)
    private String nickname;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private MemberRole role;

    @CreatedDate
    @Column(updatable = false, nullable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    private Instant updatedAt;

    @Column(name = "email_verified_at", nullable = true)
    private Instant emailVerifiedAt = null;

    // --- 연관 관계 ---
    @OneToOne(mappedBy = "member", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private Profile profile;

    @OneToOne(mappedBy = "member", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private MemberActivityRegion activityRegion;

    @OneToMany(mappedBy = "author", fetch = FetchType.LAZY)
    private List<Feed> feeds = new ArrayList<>();

    @OneToMany(mappedBy = "author", fetch = FetchType.LAZY)
    private List<GroupFeed> groupFeeds = new ArrayList<>();

    @OneToMany(mappedBy = "follower", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<Follow> following = new ArrayList<>();

    @OneToMany(mappedBy = "following", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<Follow> followers = new ArrayList<>();

    // --- 생성자 ---
    public Member(String username, String password, String nickname, MemberRole role) {
        this.username = username;
        this.password = password;
        this.nickname = nickname;
        this.role = role;
        this.profile = new Profile(this); // Profile과의 일관성을 보장
    }

    // --- 비즈니스 메서드 ---
    public void updateNickname(String nickname) {
        this.nickname = nickname;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public void setEmailVerifiedAt(Instant verifiedTime){
        this.emailVerifiedAt = verifiedTime;
    }

}