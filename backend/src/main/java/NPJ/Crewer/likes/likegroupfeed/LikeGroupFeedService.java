package NPJ.Crewer.likes.likegroupfeed;

import NPJ.Crewer.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.feeds.groupfeed.GroupFeedRepository;

import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class LikeGroupFeedService {
    private final GroupFeedRepository groupFeedRepository;
    private final LikeGroupFeedRepository likeGroupFeedRepository;
    private final MemberRepository memberRepository;

    //좋아요 누르기
    @Transactional
    public long toggleLike(Long groupFeedId, Long memberId) {
        //사용자 예외 처리
        Member liker = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

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
    public boolean isLikedByUser(Long groupFeedId, Long memberId) {
        //사용자 예외 처리
        Member liker = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("해당 피드를 찾을 수 없습니다."));

        return likeGroupFeedRepository.existsByGroupFeedAndLiker(groupFeed, liker);
    }
}
