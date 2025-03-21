package NPJ.Crewer.like.likeGroupFeed;

import NPJ.Crewer.feed.groupFeed.GroupFeed;
import NPJ.Crewer.feed.groupFeed.GroupFeedRepository;

import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class LikeGroupFeedService {
    private final GroupFeedRepository groupFeedRepository;
    private final LikeGroupFeedRepository likeGroupFeedRepository;

    //좋아요 누르기
    @Transactional
    public long toggleLike(Long groupFeedId, Member liker) {
        //좋아요할 사용자 찾기
        if (liker == null) {
            throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");
        }

        //좋아요할 피드 찾기
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("피드를 찾을 수 없습니다."));

        //좋아요 여부 확인 후 토글
        Optional<LikeGroupFeed> existingLike = likeGroupFeedRepository.findByGroupFeedAndLiker(groupFeed, liker);

        if (existingLike.isPresent()) {
            likeGroupFeedRepository.delete(existingLike.get()); // 이미 눌렀으면 삭제
        } else {
            LikeGroupFeed likeGroupFeed = LikeGroupFeed.builder()
                    .liker(liker)
                    .groupFeed(groupFeed)
                    .build();
            likeGroupFeedRepository.save(likeGroupFeed); // 없으면 저장
        }
        return likeGroupFeedRepository.countByGroupFeedId(groupFeedId);
    }

    //좋아요 수 불러오기
    @Transactional(readOnly = true)
    public long countLikes(Long groupFeedId) {
        return likeGroupFeedRepository.countByGroupFeedId(groupFeedId);
    }

    //피드를 좋아요 했는지 확인
    @Transactional(readOnly = true)
    public boolean isLikedByUser(Long groupFeedId, Member liker) {
        if (liker == null) {
            return false;
        }

        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("해당 피드를 찾을 수 없습니다."));

        return likeGroupFeedRepository.existsByGroupFeedAndLiker(groupFeed, liker);
    }
}
