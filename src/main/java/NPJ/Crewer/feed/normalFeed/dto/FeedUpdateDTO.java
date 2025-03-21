package NPJ.Crewer.feed.normalFeed.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FeedUpdateDTO {

    private String title;

    private String content;
}