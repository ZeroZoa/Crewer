package NPJ.Crewer.feeds.feed.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class FeedCreateDTO {

    @Size(min = 1, max = 40, message = "제목은 40자 이하로 입력해주세요.")
    private String title;

    @Size(min = 1, max = 1000, message = "내용은 1000자 이하로 입력해주세요.")
    private String content;
}