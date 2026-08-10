package NPJ.Crewer.dto.feeds.groupfeed;

import jakarta.validation.constraints.*;
import lombok.*;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.Instant;


@Getter
@Setter
@AllArgsConstructor
@Builder
public class GroupFeedCreateDTO {

    @NotEmpty(message = "제목을 입력해주세요.")
    @Size(max = 40, message = "제목은 40자 이하로 입력해주세요.")
    private String title;

    @NotEmpty(message = "내용을 입력해주세요.")
    @Size(max = 1000, message = "내용은 1000자 이하로 입력해주세요.")
    private String content;

    @Min(value = 2, message = "최소 2명 이상이어야 합니다.") //최소 인원 제한 (예: 2명 이상)
    @Max(value = 10, message = "최대 10명까지만 가능합니다.") //최대 인원 제한 (예: 10명 이하)
    private int maxParticipants;

    @NotBlank(message = "모임 장소를 입력해주세요.")
    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
    private final String meetingPlace;

    @NotNull(message = "위도를 입력해주세요.")
    private final Double latitude;

    @NotNull(message = "경도를 입력해주세요.")
    private final Double longitude;

    @NotNull(message = "마감 시간을 입력해주세요.")
    @Future(message = "마감 시간은 현재 시간 이후로 설정해야 합니다.")
    private final Instant deadline;

}