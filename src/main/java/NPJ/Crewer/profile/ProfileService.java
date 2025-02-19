package NPJ.Crewer.profile;

import NPJ.Crewer.feed.Feed;
import NPJ.Crewer.feed.FeedRepository;
import NPJ.Crewer.like.LikeFeed;
import NPJ.Crewer.like.LikeFeedRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;


@Service
@RequiredArgsConstructor
public class ProfileService {

    private final MemberRepository memberRepository;
    private final FeedRepository feedRepository;
    private final LikeFeedRepository likeFeedRepository;

    @Transactional(readOnly = true)
    public ProfileDTO getProfile(String username) {
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        return new ProfileDTO(
                member.getUsername(),
                member.getNickname(),
                member.getAvatarUrl()
        );
    }

    @Transactional(readOnly = true)
    public List<Feed> getFeedsByUser(String username) {
        return feedRepository.findByAuthorUsernameOrderByCreatedAtDesc(username);
    }

    @Transactional(readOnly = true)
    public List<Feed> getLikedFeeds(String username) {
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // ✅ 사용자가 좋아요한 피드 목록 가져오기
        return likeFeedRepository.findByMemberOrderByCreatedAtDesc(member)
                .stream()
                .map(LikeFeed::getFeed) // ✅ 좋아요한 피드만 가져오기
                .collect(Collectors.toList());
    }
}