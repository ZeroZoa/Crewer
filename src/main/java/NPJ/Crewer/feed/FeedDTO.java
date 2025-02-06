package NPJ.Crewer.feed;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FeedDTO {
    private String title;
    private String content;
}