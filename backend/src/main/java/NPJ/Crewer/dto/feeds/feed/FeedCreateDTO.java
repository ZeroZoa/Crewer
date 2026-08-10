package NPJ.Crewer.dto.feeds.feed;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class FeedCreateDTO {

    @NotEmpty(message = "제목을 입력해주세요.")
    @Size(max = 40, message = "제목은 40자 이하로 입력해주세요.")
    private String title;

    @NotEmpty(message = "내용을 입력해주세요.")
    @Size(max = 1000, message = "내용은 1000자 이하로 입력해주세요.")
    private String content;
}