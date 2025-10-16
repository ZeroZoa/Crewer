package NPJ.Crewer.feeds.groupfeed;

import NPJ.Crewer.chat.chatparticipant.ChatParticipant;
import NPJ.Crewer.chat.chatparticipant.ChatParticipantRepository;
import NPJ.Crewer.chat.chatroom.ChatRoom;
import NPJ.Crewer.chat.chatroom.ChatRoomRepository;
import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
import NPJ.Crewer.comments.groupfeedcomment.GroupFeedCommentRepository;
import NPJ.Crewer.feeds.groupfeed.dto.GroupFeedCreateDTO;
import NPJ.Crewer.feeds.groupfeed.dto.GroupFeedDetailResponseDTO;
import NPJ.Crewer.feeds.groupfeed.dto.GroupFeedResponseDTO;
import NPJ.Crewer.feeds.groupfeed.dto.GroupFeedUpdateDTO;
import NPJ.Crewer.feeds.groupfeed.dto.GroupFeedCompleteResponseDTO;
import NPJ.Crewer.likes.likegroupfeed.LikeGroupFeedRepository;
import NPJ.Crewer.member.Member;
import NPJ.Crewer.member.MemberRepository;
import NPJ.Crewer.notification.NotificationService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.security.access.AccessDeniedException;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.List;


@Service
@RequiredArgsConstructor
public class GroupFeedService {

    private final GroupFeedRepository groupFeedRepository;
    private final LikeGroupFeedRepository likeGroupFeedRepository;
    private final GroupFeedCommentRepository groupFeedCommentRepository;

    private final ChatRoomRepository chatRoomRepository;
    private final ChatParticipantRepository chatParticipantRepository;
    private final MemberRepository memberRepository;
    private final NotificationService notificationService;

    // GroupFeed 생성 (채팅방까지 자동 생성)
    @Transactional
    public GroupFeedResponseDTO createGroupFeed(GroupFeedCreateDTO groupFeedCreateDTO, Long memberId) {

        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // ChatRoom 생성 (maxParticipants 설정)
        ChatRoom chatRoom = ChatRoom.builder()
                .name(groupFeedCreateDTO.getTitle())
                .maxParticipants(groupFeedCreateDTO.getMaxParticipants())//DTO에서 값 가져오기
                .type(ChatRoom.ChatRoomType.GROUP)
                .build();
        chatRoomRepository.save(chatRoom);

        // GroupFeed 생성
        GroupFeed groupFeed = GroupFeed.builder()
                .title(groupFeedCreateDTO.getTitle())
                .content(groupFeedCreateDTO.getContent())
                .author(member)
                .chatRoom(chatRoom)
                .meetingPlace(groupFeedCreateDTO.getMeetingPlace())
                .latitude(groupFeedCreateDTO.getLatitude())
                .longitude(groupFeedCreateDTO.getLongitude())
                .deadline(groupFeedCreateDTO.getDeadline())
                .build();
        GroupFeed savedGroupFeed = groupFeedRepository.save(groupFeed);

        // currentParticipants 값을 1 증가시킴
        chatRoom.addParticipant();

        // 그룹피드 생성 후, 작성자를 해당 ChatRoom에 바로 추가
        // 정원 체크는 ChatRoom.addParticipant() 메서드 내부에서 처리됨
        ChatParticipant participant = ChatParticipant.builder()
                .chatRoom(chatRoom)
                .member(member)
                .build();
        chatParticipantRepository.save(participant);

        //GroupFeed 정보 반환 (안전한 방법으로 DTO 생성)
        return new GroupFeedResponseDTO(
            groupFeed.getId(),
            groupFeed.getTitle(),
            groupFeed.getContent(),
            groupFeed.getAuthor().getNickname(),
            groupFeed.getAuthor().getUsername(),
            groupFeed.getAuthor().getProfile().getAvatarUrl(),
            groupFeed.getMeetingPlace(),
            groupFeed.getLatitude(),
            groupFeed.getLongitude(),
            groupFeed.getDeadline(),
            groupFeed.getChatRoom().getId(),
            groupFeed.getChatRoom().getCurrentParticipants(),
            groupFeed.getChatRoom().getMaxParticipants(),
            groupFeed.getCreatedAt(),
            0L, // likesCount = 0 (새로 생성된 그룹피드)
            0L  // commentsCount = 0 (새로 생성된 그룹피드)
        );
    }

    //모든 GroupFeed 리스트 조회 최신순(페이징 20개씩)
    @Transactional(readOnly = true)
    public Page<GroupFeedResponseDTO> getAllGroupFeedsNew(Pageable pageable) {
        Page<Long> idsPage = groupFeedRepository.findGroupFeedIds(pageable);
        List<Long> ids = idsPage.getContent();

        if (ids.isEmpty()) {
            return Page.empty(pageable);
        }

        List<GroupFeedResponseDTO> content = groupFeedRepository.findGroupFeedInfoByIds(ids);
        return new PageImpl<>(content, pageable, idsPage.getTotalElements());
    }

    //모든 GroupFeed 리스트 조회 인기순(페이징 20개씩)
    @Transactional(readOnly = true)
    public Page<GroupFeedResponseDTO> getAllHotGroupFeeds(Pageable pageable) {
        Instant threeDaysAgo = Instant.now().minus(7, ChronoUnit.DAYS);
        Page<Long> idsPage = groupFeedRepository.findHotGroupFeedIds(threeDaysAgo, pageable);
        List<Long> ids = idsPage.getContent();

        if (ids.isEmpty()) {
            return Page.empty(pageable);
        }

        List<GroupFeedResponseDTO> content = groupFeedRepository.findGroupFeedInfoByIds(ids);
        return new PageImpl<>(content, pageable, idsPage.getTotalElements());
    }



    //Deadline이 6시간 남거나 currentParticipant/maxParticipant >=0.6 이상인 GroupFeeds
    @Transactional(readOnly = true)
    public Page<GroupFeedResponseDTO> getAlmostFullGroupFeeds(Pageable pageable) {
        Instant sixHoursAgo = Instant.now().minus(72, ChronoUnit.HOURS);
        Page<Long> idsPage = groupFeedRepository.findAlmostFullGroupFeedIds(sixHoursAgo, pageable);
        List<Long> ids = idsPage.getContent();

        if (ids.isEmpty()) {
            return Page.empty(pageable);
        }

        List<GroupFeedResponseDTO> content = groupFeedRepository.findGroupFeedInfoByIds(ids);
        return new PageImpl<>(content, pageable, idsPage.getTotalElements());
    }

    @Transactional(readOnly = true) // 데이터를 단순히 읽어오는 것이므로 readOnly = true로 설정하여 성능 최적화
    public List<GroupFeedResponseDTO> findLatestTwoGroupFeeds() {
        Pageable topTwo = PageRequest.of(0, 2);
        Page<Long> idsPage = groupFeedRepository.findGroupFeedIds(topTwo);
        if (idsPage.getContent().isEmpty()) {
            return Collections.emptyList();
        }
        return groupFeedRepository.findGroupFeedInfoByIds(idsPage.getContent());
    }

    @Transactional(readOnly = true)
    public Page<GroupFeedResponseDTO> getGroupFeedsByKeyword(Pageable pageable, String keyword) {
        Page<Long> groupFeedIdsPage = groupFeedRepository.findIdsByKeyword(keyword, pageable);
        List<Long> ids = groupFeedIdsPage.getContent();

        if (ids.isEmpty()) {
            return Page.empty(pageable);
        }

        List<GroupFeedResponseDTO> content = groupFeedRepository.findGroupFeedInfoByIds(ids);

        return new PageImpl<>(content, pageable, groupFeedIdsPage.getTotalElements());
    }


    //특정 GroupFeed 상세 조회
    @Transactional(readOnly = true)
    public GroupFeedDetailResponseDTO getGroupFeedById(Long groupFeedId, Long memberId) {

        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("GroupFeed을 찾을 수 없습니다."));

        Member currentMember = null;

        if (memberId != null) {
            currentMember = memberRepository.findById(memberId).orElse(null);
        }

        return new GroupFeedDetailResponseDTO(groupFeed, currentMember);
    }

    //GroupFeed 수정 (작성자만 가능)
    @Transactional
    public GroupFeedResponseDTO updateGroupFeed(Long groupFeedId, Long memberId, GroupFeedUpdateDTO groupFeedUpdateDTO) {
        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        //피드 조회 (없으면 예외 발생)
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("GroupFeed을 찾을 수 없습니다."));

        //수정 권한 확인 (작성자만 가능)
        if (!groupFeed.getAuthor().getUsername().equals(member.getUsername())) {
            throw new AccessDeniedException("본인이 작성한 글만 수정할 수 있습니다.");
        }

        //Feed 수정
        groupFeed.update(groupFeedUpdateDTO.getTitle(), groupFeedUpdateDTO.getContent(), groupFeedUpdateDTO.getMaxParticipants(), groupFeedUpdateDTO.getMeetingPlace(), groupFeedUpdateDTO.getLatitude(), groupFeedUpdateDTO.getLongitude(),groupFeedUpdateDTO.getDeadline());

        return new GroupFeedResponseDTO(groupFeed);
    }

    //수정할 피드 내용 불러오기
    @Transactional(readOnly = true)
    public GroupFeedUpdateDTO getGroupFeedForUpdate(Long groupFeedId, Long memberId) {
        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        //GroupFeed 불러오기
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("GroupFeed을을 찾을 수 없습니다."));

        //피드를 수정할 권한 확인 (작성자만 가능)
        if (!groupFeed.getAuthor().getUsername().equals(member.getUsername())){
            throw new AccessDeniedException("본인이 작성한 글만 수정할 수 있습니다.");
        }

        return new GroupFeedUpdateDTO(
                groupFeed.getTitle(),
                groupFeed.getContent(),
                groupFeed.getChatRoom().getMaxParticipants(),
                groupFeed.getMeetingPlace(),
                groupFeed.getLatitude(),
                groupFeed.getLongitude(),
                groupFeed.getDeadline()
        );
    }

    //GroupFeed 삭제 (채팅방 유지 또는 삭제 옵션 추가 가능)
    @Transactional
    public void deleteGroupFeed(Long groupFeedId, Long memberId, boolean deleteChatRoom) {
        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        //GroupFeed 조회 (없으면 예외 발생)
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("GroupFeed를 찾을 수 없습니다."));

        if (!groupFeed.getAuthor().getUsername().equals(member.getUsername())) {
            throw new AccessDeniedException("본인이 작성한 글만 삭제할 수 있습니다.");
        }

        //채팅방 객체 미리 저장
        ChatRoom chatRoom = groupFeed.getChatRoom();

        groupFeedRepository.delete(groupFeed);

        if (deleteChatRoom && chatRoom != null) {
            chatRoomRepository.delete(chatRoom);
        }
    }

    @Transactional
    public ChatRoomResponseDTO joinChatRoom(Long groupFeedId, Long memberId) {
        //사용자 예외 처리
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new EntityNotFoundException("회원 정보가 없습니다."));

        // GroupFeed 조회 (없으면 예외 발생)
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("GroupFeed를 찾을 수 없습니다."));

        // GroupFeed에 연결된 ChatRoom 조회
        ChatRoom chatRoom = groupFeed.getChatRoom();
        if (chatRoom == null) {
            throw new IllegalArgumentException("해당 그룹 피드에 연결된 채팅방이 없습니다.");
        }

        // 이미 참여 중인 경우, capacity 체크 없이 바로 반환
        ChatParticipant existingParticipant = chatParticipantRepository
                .findByChatRoomIdAndMemberId(chatRoom.getId(), memberId);
        if (existingParticipant != null) {
            return ChatRoomResponseDTO.builder()
                    .id(chatRoom.getId())
                    .name(chatRoom.getName())
                    .maxParticipants(chatRoom.getMaxParticipants())
                    .currentParticipants(chatRoom.getCurrentParticipants())
                    .build();
        }

        // 정원 체크: 현재 참가 인원이 최대 인원과 같거나 많으면 예외 발생
        if (chatRoom.getCurrentParticipants() >= chatRoom.getMaxParticipants()) {
            throw new IllegalStateException("정원이 초과되어 참가할 수 없습니다.");
        }

        // ChatRoom의 currentParticipants 업데이트 (도메인 메서드 활용)
        chatRoom.addParticipant();

        // 새 ChatParticipant 생성 및 저장 (이미 Member 객체가 매개변수로 주어졌으므로 조회 불필요)
        ChatParticipant participant = ChatParticipant.builder()
                .chatRoom(chatRoom)
                .member(member)
                .build();
        chatParticipantRepository.save(participant);

        // ChatRoom 정보를 Builder로 DTO에 변환하여 반환
        return ChatRoomResponseDTO.builder()
                .id(chatRoom.getId())
                .name(chatRoom.getName())
                .maxParticipants(chatRoom.getMaxParticipants())
                .currentParticipants(chatRoom.getCurrentParticipants())
                .build();
    }

    public GroupFeed save(GroupFeed groupFeed) {
        return groupFeedRepository.save(groupFeed);
    }

    // 채팅방 ID로 GroupFeed 조회 (엔티티 반환 - 내부 사용용)
    public GroupFeed findByChatRoomId(String chatRoomId) {
        return groupFeedRepository.findByChatRoomId(java.util.UUID.fromString(chatRoomId))
                .orElseThrow(() -> new EntityNotFoundException("GroupFeed not found with chatRoomId: " + chatRoomId));
    }
    
    // 채팅방 ID로 GroupFeed 기본 정보만 조회 (DTO 반환)
    public GroupFeedCompleteResponseDTO findBasicInfoByChatRoomId(String chatRoomId) {
        GroupFeed groupFeed = groupFeedRepository.findByChatRoomId(java.util.UUID.fromString(chatRoomId))
                .orElseThrow(() -> new EntityNotFoundException("GroupFeed not found with chatRoomId: " + chatRoomId));
        
        return GroupFeedCompleteResponseDTO.builder()
                .id(groupFeed.getId())
                .title(groupFeed.getTitle())
                .status(groupFeed.getStatus().name())
                .message("")
                .build();
    }
    
    // 모임 종료 처리 (DTO 반환) - 완전한 DTO 패턴
    @Transactional
    public GroupFeedCompleteResponseDTO completeGroupFeedByChatRoom(String chatRoomId, Long memberId) {
        // 1단계: GroupFeed ID 조회
        Long groupFeedId = groupFeedRepository.findIdByChatRoomId(java.util.UUID.fromString(chatRoomId))
                .orElseThrow(() -> new EntityNotFoundException("GroupFeed not found with chatRoomId: " + chatRoomId));
        
        // 2단계: 작성자 ID 조회
        Long authorId = groupFeedRepository.findAuthorIdByChatRoomId(java.util.UUID.fromString(chatRoomId))
                .orElseThrow(() -> new EntityNotFoundException("Author not found for chatRoomId: " + chatRoomId));
        
        // 3단계: 작성자 확인
        if (!authorId.equals(memberId)) {
            throw new AccessDeniedException("Only the author can complete the group feed");
        }
        
        // 4단계: 이미 완료된 모임인지 확인
        GroupFeedStatus currentStatus = groupFeedRepository.findStatusById(groupFeedId)
                .orElseThrow(() -> new EntityNotFoundException("GroupFeed status not found"));
        
        if (currentStatus == GroupFeedStatus.COMPLETED) {
            // 이미 완료된 모임인 경우 정상 응답으로 반환 (오류가 아님)
            return GroupFeedCompleteResponseDTO.builder()
                    .id(groupFeedId)
                    .title(groupFeedRepository.findTitleById(groupFeedId).orElse("모임"))
                    .status(GroupFeedStatus.COMPLETED.name())
                    .message("이미 종료된 모임입니다.")
                    .build();
        }
        
        // 5단계: 제목 조회
        String title = groupFeedRepository.findTitleById(groupFeedId)
                .orElse("모임");
        
        // 6단계: 모임 상태를 완료로 변경 (엔티티 조회 없이 직접 업데이트)
        groupFeedRepository.updateStatusToCompleted(groupFeedId);
        
        return GroupFeedCompleteResponseDTO.builder()
                .id(groupFeedId)
                .title(title)
                .status(GroupFeedStatus.COMPLETED.name())
                .message("모임이 성공적으로 종료되었습니다.")
                .build();
    }
    
    // 모임 종료 처리 + 알림 생성 (Controller에서 호출)
    @Transactional
    public GroupFeedCompleteResponseDTO completeGroupFeedWithNotifications(String chatRoomId, Long memberId) {
        // 모임 종료 처리
        GroupFeedCompleteResponseDTO response = completeGroupFeedByChatRoom(chatRoomId, memberId);
        
        // 실제로 새로 종료된 모임인 경우에만 알림 생성
        if ("모임이 성공적으로 종료되었습니다.".equals(response.getMessage())) {
            notificationService.createEvaluationRequestNotifications(
                response.getId(), 
                response.getTitle(), 
                chatRoomId
            );
        }
        
        return response;
    }

    // 그룹 피드 참여자 목록 조회
    public List<Map<String, Object>> getGroupFeedParticipants(Long groupFeedId) {
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("GroupFeed not found with id: " + groupFeedId));
        
        // 채팅방의 모든 참여자 조회
        List<ChatParticipant> participants = chatParticipantRepository.findByChatRoomId(groupFeed.getChatRoom().getId());
        
        // 참여자 정보를 Map으로 변환
        return participants.stream()
                .map(participant -> {
                    Map<String, Object> participantInfo = new HashMap<>();
                    participantInfo.put("id", participant.getMember().getId());
                    participantInfo.put("nickname", participant.getMember().getNickname());
                    participantInfo.put("username", participant.getMember().getUsername());
                    // Profile에서 avatarUrl 가져오기 (Profile이 없으면 기본값 사용)
                    String avatarUrl = participant.getMember().getProfile() != null 
                        ? participant.getMember().getProfile().getAvatarUrl() 
                        : "/images/default-avatar.png";
                    participantInfo.put("avatarUrl", avatarUrl);
                    return participantInfo;
                })
                .collect(Collectors.toList());
    }
}