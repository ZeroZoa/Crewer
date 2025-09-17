package NPJ.Crewer.profile;

import NPJ.Crewer.feeds.feed.Feed;
import NPJ.Crewer.feeds.feed.FeedRepository;
import NPJ.Crewer.feeds.feed.dto.FeedResponseDTO;
import NPJ.Crewer.follow.FollowRepository;
import NPJ.Crewer.likes.likefeed.LikeFeedRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProfileService {
    private final MemberRepository memberRepository;
    private final FeedRepository feedRepository;
    private final LikeFeedRepository likeFeedRepository;
    private final FollowRepository followRepository;

    @Value("${upload.dir}")
    private String uploadDir;


    //사용자의 프로필 정보 조회
    @Transactional(readOnly = true)
    public ProfileDTO getMyProfile(Long memberId) {

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // 팔로워/팔로잉 수 계산
        long followersCount = followRepository.countByFollowing(member);
        long followingCount = followRepository.countByFollower(member);

        return ProfileDTO.builder()
                .username(member.getUsername())
                .nickname(member.getNickname())
                .avatarUrl(member.getProfile().getAvatarUrl())
                .temperature(member.getProfile().getTemperature())
                .interests(member.getProfile().getInterests())
                .followersCount((int) followersCount)
                .followingCount((int) followingCount)
                .build();
    }

    @Transactional(readOnly = true)
    public List<FeedResponseDTO> getMyFeeds(Long memberId) {

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        return feedRepository.findByAuthor(member).stream()
                .map(feed -> new FeedResponseDTO(
                        feed.getId(),
                        feed.getTitle(),
                        feed.getContent(),
                        feed.getAuthorNickname(),
                        feed.getAuthorUsername(),
                        feed.getAuthorAvatarUrl(),
                        feed.getCreatedAt(),
                        feed.getLikesCount(),
                        feed.getCommentsCount()
                ))
                .collect(Collectors.toList());
    }

    /**
     * 사용자가 좋아요한 피드 목록 조회 (DTO 변환)
     */
    @Transactional(readOnly = true)
    public List<FeedResponseDTO> getMyLikedFeeds(Long memberId) {

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        return likeFeedRepository.findByLikerOrderByCreatedAtDesc(member).stream()
                .map(likeFeed -> {
                    Feed feed = likeFeed.getFeed();
                    return new FeedResponseDTO(
                            feed.getId(),
                            feed.getTitle(),
                            feed.getContent(),
                            feed.getAuthor().getNickname(),
                            feed.getAuthor().getUsername(),
                            feed.getAuthor().getProfile().getAvatarUrl(),
                            feed.getCreatedAt(),
                            feed.getLikes().size(),
                            feed.getComments().size()
                    );
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public List<String> updateInterests(Long memberId, List<String> interests) {
        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        Profile userProfile = member.getProfile();
        if (userProfile == null) {
            throw new IllegalStateException("프로필 정보가 존재하지 않습니다.");
        }

        userProfile.updateInterests(interests);

        return userProfile.getInterests();
    }

    @Transactional
    public String updateNickname(Long memberId, String nickname) {
        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // 닉네임 중복 검사 (자기 자신의 닉네임은 제외)
        Optional<Member> existingMember = memberRepository.findByNickname(nickname);
        if (existingMember.isPresent() && !existingMember.get().getId().equals(memberId)) {
            throw new IllegalArgumentException("이미 사용 중인 닉네임입니다.");
        }

        // 닉네임 업데이트
        member.updateNickname(nickname);

        return member.getNickname();
    }

    //사용자명으로 프로필 정보 조회
    @Transactional(readOnly = true)
    public ProfileDTO getProfileByUsername(String username) {
        //사용자 예외 처리
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // 팔로워/팔로잉 수 계산
        long followersCount = followRepository.countByFollowing(member);
        long followingCount = followRepository.countByFollower(member);

        return ProfileDTO.builder()
                .username(member.getUsername())
                .nickname(member.getNickname())
                .avatarUrl(member.getProfile().getAvatarUrl())
                .temperature(member.getProfile().getTemperature())
                .interests(member.getProfile().getInterests())
                .followersCount((int) followersCount)
                .followingCount((int) followingCount)
                .build();
    }

    //사용자명으로 Member 엔티티 조회
    @Transactional(readOnly = true)
    public Member getMemberByUsername(String username) {
        return memberRepository.findByUsername(username)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));
    }

    // 프로필 이미지 업로드
    @Transactional
    public ResponseEntity<String> uploadProfileImage(Long memberId, MultipartFile image) {

        try {
            // 사용자 예외 처리
            Member member = memberRepository.findById(memberId)
                    .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

            // 프로필 디렉토리 생성
            File directory = new File(uploadDir + "/profile");
            
            if (!directory.exists()) {
                directory.mkdirs();
            }
            
            // 저장할 파일 경로
            String fileName = memberId + "_" + image.getOriginalFilename();
            Path filePath = Paths.get(uploadDir + "/profile", fileName);
            String fileUrl = "/crewerimages/profile/" + fileName;

            // 파일 저장
            Files.write(filePath, image.getBytes());

            // 프로필의 avatarUrl 업데이트
            Profile userProfile = member.getProfile();
            if (userProfile == null) {
                throw new IllegalStateException("프로필 정보가 존재하지 않습니다.");
            }
            
            userProfile.updateAvatarUrl(fileUrl);

            return ResponseEntity.ok(fileUrl);
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Upload Fail");
        }
    }
}
