package NPJ.Crewer.feed.groupFeed;

import NPJ.Crewer.chat.chatparticipant.ChatParticipant;
import NPJ.Crewer.chat.chatparticipant.ChatParticipantRepository;
import NPJ.Crewer.chat.chatroom.ChatRoom;
import NPJ.Crewer.chat.chatroom.ChatRoomRepository;
import NPJ.Crewer.chat.chatroom.dto.ChatRoomResponseDTO;
import NPJ.Crewer.comment.groupFeedComment.GroupFeedCommentRepository;
import NPJ.Crewer.feed.groupFeed.dto.GroupFeedCreateDTO;
import NPJ.Crewer.feed.groupFeed.dto.GroupFeedResponseDTO;
import NPJ.Crewer.feed.groupFeed.dto.GroupFeedUpdateDTO;
import NPJ.Crewer.like.likeGroupFeed.LikeGroupFeedRepository;
import NPJ.Crewer.member.Member;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class GroupFeedService {

    private final GroupFeedRepository groupFeedRepository;
    private final LikeGroupFeedRepository likeGroupFeedRepository;
    private final GroupFeedCommentRepository groupFeedCommentRepository;

    private final ChatRoomRepository chatRoomRepository;
    private final ChatParticipantRepository chatParticipantRepository;

    // GroupFeed 생성 (채팅방까지 자동 생성)
    @Transactional
    public GroupFeedResponseDTO createGroupFeed(GroupFeedCreateDTO groupFeedCreateDTO, Member member) {
        //사용자 예외 처리
        if (member == null) {
            throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");
        }

        // ChatRoom 생성 (maxParticipants 설정)
        ChatRoom chatRoom = ChatRoom.builder()
                .name(groupFeedCreateDTO.getTitle())
                .maxParticipants(groupFeedCreateDTO.getMaxParticipants()) //DTO에서 값 가져오기
                .build();
        chatRoomRepository.save(chatRoom);

        // GroupFeed 생성
        GroupFeed groupFeed = GroupFeed.builder()
                .title(groupFeedCreateDTO.getTitle())
                .content(groupFeedCreateDTO.getContent())
                .author(member)
                .chatRoom(chatRoom)
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

        //GroupFeed 정보 반환
        return new GroupFeedResponseDTO(
                savedGroupFeed.getId(),
                savedGroupFeed.getTitle(),
                savedGroupFeed.getContent(),
                savedGroupFeed.getAuthor().getNickname(),
                savedGroupFeed.getChatRoom().getId(),
                savedGroupFeed.getCreatedAt(),
                0,
                0

        );
    }

    //모든 GroupFeed 리스트 조회 (페이징 20개씩)
    @Transactional(readOnly = true)
    public Page<GroupFeedResponseDTO> getAllGroupFeeds(Pageable pageable) {
        return groupFeedRepository.findAll(pageable).map(groupFeed ->{
            int likesCount = groupFeedRepository.countLikesByGroupFeedId(groupFeed.getId()); // 좋아요 개수
            int commentsCount = groupFeedRepository.countCommentsByGroupFeedId(groupFeed.getId()); // 댓글 개수

            return new GroupFeedResponseDTO(
                    groupFeed.getId(),
                    groupFeed.getTitle(),
                    groupFeed.getContent(),
                    groupFeed.getAuthor().getNickname(),
                    groupFeed.getChatRoom().getId(),
                    groupFeed.getCreatedAt(),
                    likesCount,
                    commentsCount
            );
        });
    }

    //특정 GroupFeed 상세 조회
    @Transactional(readOnly = true)
    public GroupFeedResponseDTO getGroupFeedById(Long groupFeedId) {
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("GroupFeed을 찾을 수 없습니다."));

        int likesCount = groupFeedRepository.countLikesByGroupFeedId(groupFeed.getId()); // 좋아요 개수
        int commentsCount = groupFeedRepository.countCommentsByGroupFeedId(groupFeed.getId()); // 댓글 개수

        return new GroupFeedResponseDTO(
                groupFeed.getId(),
                groupFeed.getTitle(),
                groupFeed.getContent(),
                groupFeed.getAuthor().getNickname(),
                groupFeed.getChatRoom().getId(),
                groupFeed.getCreatedAt(),
                likesCount,
                commentsCount
        );
    }

    //GroupFeed 수정 (작성자만 가능)
    @Transactional
    public GroupFeedResponseDTO updateGroupFeed(Long groupFeedId, Member member, GroupFeedUpdateDTO groupFeedUpdateDTO) {

        //사용자 예외 처리
        if (member == null) {
            throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");
        }

        //피드 조회 (없으면 예외 발생)
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("GroupFeed을 찾을 수 없습니다."));

        //수정 권한 확인 (작성자만 가능)
        if (!groupFeed.getAuthor().getUsername().equals(member.getUsername())) {
            throw new AccessDeniedException("본인이 작성한 글만 수정할 수 있습니다.");
        }

        //Feed 수정
        groupFeed.update(groupFeedUpdateDTO.getTitle(), groupFeedUpdateDTO.getContent(), groupFeedUpdateDTO.getMaxParticipants());

        int likesCount = groupFeedRepository.countLikesByGroupFeedId(groupFeed.getId()); // 좋아요 개수
        int commentsCount = groupFeedRepository.countCommentsByGroupFeedId(groupFeed.getId()); // 댓글 개수

        return new GroupFeedResponseDTO(
                groupFeed.getId(),
                groupFeed.getTitle(),
                groupFeed.getContent(),
                groupFeed.getAuthor().getNickname(),
                groupFeed.getChatRoom().getId(),
                groupFeed.getCreatedAt(),
                likesCount,
                commentsCount
        );
    }

    //수정할 피드 내용 불러오기
    @Transactional(readOnly = true)
    public GroupFeedUpdateDTO getGroupFeedForUpdate(Long groupFeedId, Member member) {
        //사용자 예외 처리
        if (member == null) {
            throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");
        }

        //GroupFeed 불러오기
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("GroupFeed을을 찾을 수 없습니다."));

        //피드를 수정할 권한 확인 (작성자만 가능)
        if (!groupFeed.getAuthor().getUsername().equals(member.getUsername())){
            throw new AccessDeniedException("본인이 작성한 글만 수정할 수 있습니다.");
        }

        return new GroupFeedUpdateDTO(groupFeed.getTitle(), groupFeed.getContent(), groupFeed.getChatRoom().getMaxParticipants());
    }

    //GroupFeed 삭제 (채팅방 유지 또는 삭제 옵션 추가 가능)
    @Transactional
    public void deleteGroupFeed(Long groupFeedId, Member member, boolean deleteChatRoom) {

        //사용자 예외 처리
        if (member == null) {
            throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");
        }

        // GroupFeed 조회 (없으면 예외 발생)
        GroupFeed groupFeed = groupFeedRepository.findById(groupFeedId)
                .orElseThrow(() -> new IllegalArgumentException("GroupFeed를 찾을 수 없습니다."));

        if (!groupFeed.getAuthor().getUsername().equals(member.getUsername())) {
            throw new AccessDeniedException("본인이 작성한 글만 삭제할 수 있습니다.");
        }

        ChatRoom chatRoom = groupFeed.getChatRoom();

        //1. 해당 피드의 모든 좋아요 삭제
        likeGroupFeedRepository.deleteByGroupFeedId(groupFeedId);

        //2. 해당 피드의 모든 댓글 삭제
        groupFeedCommentRepository.deleteByGroupFeedId(groupFeedId);

        //3. GroupFeed 삭제
        groupFeedRepository.delete(groupFeed);

        // 채팅방 삭제 여부 결정
        if (deleteChatRoom) {
            chatRoomRepository.delete(chatRoom);
        }
    }

    @Transactional
    public ChatRoomResponseDTO joinChatRoom(Long groupFeedId, Member member) {

        //사용자 예외 처리
        if (member == null) {
            throw new IllegalArgumentException("사용자 정보를 찾을 수 없습니다.");
        }

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
                .findByChatRoomIdAndMemberUsername(chatRoom.getId(), member.getUsername());
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
}