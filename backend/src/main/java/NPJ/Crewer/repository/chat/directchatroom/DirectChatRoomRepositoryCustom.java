package NPJ.Crewer.repository.chat.directchatroom;

import NPJ.Crewer.dto.chat.directchatroom.DirectChatRoomResponseDTO;

import java.util.List;

public interface DirectChatRoomRepositoryCustom {

    // 1:1 채팅방 + 상대 프로필 가져오기
    List<DirectChatRoomResponseDTO> findDirectChatRoomsWithAvartar(Long myUserId);
}
