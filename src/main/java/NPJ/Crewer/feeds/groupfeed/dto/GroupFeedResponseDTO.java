package NPJ.Crewer.feeds.groupfeed.dto;

import NPJ.Crewer.feeds.groupfeed.GroupFeed;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.Instant;
import java.util.UUID;

@Getter
@AllArgsConstructor
public class GroupFeedResponseDTO {
    private Long id;
    private String title;
    private String content;
    private String authorNickname;
    private String authorUsername;
    private String meetingPlace;
    private Instant deadline;
    private UUID chatRoomId;
    private Instant createdAt;
    private int likesCount;
    private int commentsCount;

    public GroupFeedResponseDTO(GroupFeed groupFeed){
        this.id = groupFeed.getId();
        this.title = groupFeed.getTitle();
        this.content = groupFeed.getContent();
        this.authorNickname = groupFeed.getAuthor().getNickname();
        this.authorUsername = groupFeed.getAuthor().getUsername();
        this.meetingPlace = groupFeed.getMeetingPlace();
        this.deadline = groupFeed.getDeadline();
        this.chatRoomId = groupFeed.getChatRoom().getId();
        this.likesCount = groupFeed.getLikes().size();
        this.commentsCount = groupFeed.getComments().size();
    }

    public GroupFeedResponseDTO(Long id, String title, String content, String authorNickname, String authorUsername,
                                String meetingPlace, Instant deadline, UUID chatRoomId, Instant createdAt,
                                Long likesCount, Long commentsCount) {
        this.id = id;
        this.title = title;
        this.content = content;
        this.authorNickname = authorNickname;
        this.authorUsername = authorUsername;
        this.meetingPlace = meetingPlace;
        this.deadline = deadline;
        this.chatRoomId = chatRoomId;
        this.createdAt = createdAt;
        this.likesCount = likesCount.intValue();
        this.commentsCount = commentsCount.intValue();
    }
}
