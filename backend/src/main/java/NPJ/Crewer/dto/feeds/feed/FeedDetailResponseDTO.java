package NPJ.Crewer.dto.feeds.feed;

import NPJ.Crewer.dto.comments.feedcomment.FeedCommentResponseDTO;
import NPJ.Crewer.domain.feeds.feed.Feed;
import NPJ.Crewer.dto.likes.likefeed.LikeFeedResponseDTO;
import NPJ.Crewer.domain.member.Member;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;


@Getter
public class FeedDetailResponseDTO {
    private Long id;
    private String title;
    private String content;
    private String authorNickname;
    private String authorUsername;
    private String authorAvatarUrl;
    private Instant createdAt;
    private List<FeedCommentResponseDTO> comments;
    private List<LikeFeedResponseDTO> likes;
    private int commentCount;
    private int likeCount;

    @JsonProperty("isLiked")
    private boolean isLiked;

    // 서비스 레이어에서 사용할 생성자
    public FeedDetailResponseDTO(Feed feed, Member currentMember) {
        this.id = feed.getId();
        this.title = feed.getTitle();
        this.content = feed.getContent();
        this.authorNickname = feed.getAuthor().getNickname();
        this.authorUsername = feed.getAuthor().getUsername();
        this.authorAvatarUrl = feed.getAuthor().getProfile().getAvatarUrl();
        this.createdAt = feed.getCreatedAt();

        // 댓글 정보 가져오기
        this.comments = feed.getComments().stream()
                .map(FeedCommentResponseDTO::new)
                .collect(Collectors.toList());

        this.commentCount = feed.getComments().size();

        // 좋아요 정보 가져오기
        this.likes = feed.getLikes().stream()
                .map(LikeFeedResponseDTO::new)
                .collect(Collectors.toList());

        this.likeCount = feed.getLikes().size();

        if (currentMember != null) {
            this.isLiked = feed.getLikes().stream()
                    .anyMatch(like -> like.getLiker().getUsername().equals(currentMember.getUsername()));
        } else {
            this.isLiked = false;
        }
    }
}