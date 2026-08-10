package NPJ.Crewer.chat.directchatroom;

import NPJ.Crewer.chat.directchatroom.dto.DirectChatRoomResponseDTO;

import java.util.List;

public interface DirectChatRoomRepositoryCustom {

    // 1:1 채팅방 + 상대 프로필 가져오기
    List<DirectChatRoomResponseDTO> findDirectChatRoomsWithAvartar(Long myUserId);
}
