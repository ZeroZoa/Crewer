package NPJ.Crewer.service.likes.likegroupfeed;

import NPJ.Crewer.domain.likes.likegroupfeed.LikeGroupFeed;
import NPJ.Crewer.repository.likes.likegroupfeed.LikeGroupFeedRepository;

import NPJ.Crewer.domain.feeds.groupfeed.GroupFeed;
import NPJ.Crewer.repository.feeds.groupfeed.GroupFeedRepository;

import NPJ.Crewer.domain.member.Member;
import NPJ.Crewer.repository.member.MemberRepository;
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
}
