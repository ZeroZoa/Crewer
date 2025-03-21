package NPJ.Crewer.feed.groupFeed.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import lombok.*;


@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GroupFeedCreateDTO {

    @NotEmpty(message = "제목을 입력해주세요")
    private String title;

    @NotEmpty(message = "내용을 입력해주세요.")
    private String content;

    @Min(value = 2, message = "최소 2명 이상이어야 합니다.") //최소 인원 제한 (예: 2명 이상)
    @Max(value = 10, message = "최대 100명까지만 가능합니다.") //최대 인원 제한 (예: 100명 이하)
    private int maxParticipants;
}