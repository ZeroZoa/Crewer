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
    private String authorAvatarUrl;
    private String meetingPlace;
    private Double latitude;
    private Double longitude;
    private Instant deadline;
    private UUID chatRoomId;
    private int currentParticipants;
    private int maxParticipants;
    private Instant createdAt;
    private int likesCount;
    private int commentsCount;

    public GroupFeedResponseDTO(GroupFeed groupFeed){
        this.id = groupFeed.getId();
        this.title = groupFeed.getTitle();
        this.content = groupFeed.getContent();
        this.authorNickname = groupFeed.getAuthor().getNickname();
        this.authorUsername = groupFeed.getAuthor().getUsername();
        this.authorAvatarUrl = groupFeed.getAuthor().getProfile().getAvatarUrl();
        this.meetingPlace = groupFeed.getMeetingPlace();
        this.latitude = groupFeed.getLatitude();
        this.longitude = groupFeed.getLongitude();
        this.deadline = groupFeed.getDeadline();
        this.chatRoomId = groupFeed.getChatRoom().getId();
        this.currentParticipants = groupFeed.getChatRoom().getCurrentParticipants();
        this.createdAt = groupFeed.getCreatedAt();
        this.maxParticipants = groupFeed.getChatRoom().getMaxParticipants();
        this.likesCount = groupFeed.getLikes() != null ? groupFeed.getLikes().size() : 0;
        this.commentsCount = groupFeed.getComments() != null ? groupFeed.getComments().size() : 0;
    }


    public GroupFeedResponseDTO(Long id, String title, String content, String authorNickname, String authorUsername, String authorAvatarUrl,
                                String meetingPlace, Double latitude, Double longitude, Instant deadline, UUID chatRoomId, int currentParticipants, int maxParticipants, Instant createdAt,
                                Long likesCount, Long commentsCount) {
        this.id = id;
        this.title = title;
        this.content = content;
        this.authorNickname = authorNickname;
        this.authorUsername = authorUsername;
        this.authorAvatarUrl = authorAvatarUrl;
        this.meetingPlace = meetingPlace;
        this.latitude = latitude;
        this.longitude = longitude;
        this.deadline = deadline;
        this.chatRoomId = chatRoomId;
        this.currentParticipants = currentParticipants;
        this.maxParticipants =maxParticipants;
        this.createdAt = createdAt;
        this.likesCount = likesCount.intValue();
        this.commentsCount = commentsCount.intValue();
    }
}
