package NPJ.Crewer.feeds.groupfeed.dto;

import NPJ.Crewer.comments.feedcomment.dto.FeedCommentResponseDTO;
import NPJ.Crewer.comments.groupfeedcomment.dto.GroupFeedCommentResponseDTO;
import NPJ.Crewer.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.likes.likefeed.dto.LikeFeedResponseDTO;
import NPJ.Crewer.likes.likegroupfeed.dto.LikeGroupFeedResponseDTO;
import NPJ.Crewer.member.Member;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Getter
public class GroupFeedDetailResponseDTO {
    private Long id;
    private String title;
    private String content;
    private String authorNickname;
    private String authorUsername;
    private String meetingPlace;
    private Instant deadline;
    private UUID chatRoomId;
    private int currentParticipants;
    private int maxParticipants;
    private Instant createdAt;
    private List<GroupFeedCommentResponseDTO> comments;
    private List<LikeGroupFeedResponseDTO> likes;
    private int likesCount;
    private int commentsCount;

    @JsonProperty("isLiked")
    private boolean isLiked;

    public GroupFeedDetailResponseDTO(GroupFeed groupFeed, Member currentMember){
        this.id = groupFeed.getId();
        this.title = groupFeed.getTitle();
        this.content = groupFeed.getContent();
        this.authorNickname = groupFeed.getAuthor().getNickname();
        this.authorUsername = groupFeed.getAuthor().getUsername();
        this.meetingPlace = groupFeed.getMeetingPlace();
        this.deadline = groupFeed.getDeadline();
        this.chatRoomId = groupFeed.getChatRoom().getId();
        this.currentParticipants = groupFeed.getChatRoom().getCurrentParticipants();
        this.maxParticipants = groupFeed.getChatRoom().getMaxParticipants();
        this.createdAt = groupFeed.getCreatedAt();
        this.likesCount = groupFeed.getLikes().size();
        this.commentsCount = groupFeed.getComments().size();

        this.comments = groupFeed.getComments().stream()
                .map(GroupFeedCommentResponseDTO::new)
                .collect(Collectors.toList());

        this.likes = groupFeed.getLikes().stream()
                .map(LikeGroupFeedResponseDTO::new)
                .collect(Collectors.toList());

        if (groupFeed.getChatRoom() != null) {
            this.chatRoomId = groupFeed.getChatRoom().getId();
            this.currentParticipants = groupFeed.getChatRoom().getCurrentParticipants();
            this.maxParticipants = groupFeed.getChatRoom().getMaxParticipants();
        }

        if (currentMember != null) {
            this.isLiked = groupFeed.getLikes().stream()
                    .anyMatch(like -> like.getLiker().getUsername().equals(currentMember.getUsername()));
        } else {
            this.isLiked = false;
        }
    }
}
