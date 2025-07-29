class ApiConfig {
  // 개발 환경에서는 실제 컴퓨터의 IP 주소를 사용
  // 모바일에서 접근할 때는 localhost 대신 실제 IP 주소 사용
  //static const String baseUrl = 'http://본인 ip주소:8080'; // 본인 컴퓨터 IP 주소
  
  // 로컬 개발용 (에뮬레이터에서만 사용)
  static const String baseUrl = 'http://localhost:8080';
  
  // API 엔드포인트들
  static const String login = '/members/login';
  static const String signup = '/members/register';
  static const String feeds = '/feeds';
  static const String groupFeeds = '/groupfeeds';
  static const String running = '/running';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String ws = '/ws';
  
  // 편의 메서드들
  static String getFeedDetail(String feedId) => '$feeds/$feedId';
  static String getFeedComments(String feedId) => '$feeds/$feedId/comments';
  static String getFeedLikeStatus(String feedId) => '$feeds/$feedId/like/status';
  static String getFeedLike(String feedId) => '$feeds/$feedId/like';
  static String getFeedEdit(String feedId) => '$feeds/$feedId/edit';
  static String getFeedCreate() => '$feeds/create';
  
  static String getGroupFeedDetail(String groupFeedId) => '$groupFeeds/$groupFeedId';
  static String getGroupFeedComments(String groupFeedId) => '$groupFeeds/$groupFeedId/comments';
  static String getGroupFeedLikeStatus(String groupFeedId) => '$groupFeeds/$groupFeedId/like/status';
  static String getGroupFeedLike(String groupFeedId) => '$groupFeeds/$groupFeedId/like';
  static String getGroupFeedJoinChat(String groupFeedId) => '$groupFeeds/$groupFeedId/join-chat';
  static String getGroupFeedEdit(String groupFeedId) => '$groupFeeds/$groupFeedId/edit';
  static String getGroupFeedCreate() => '$groupFeeds/create';
  
  static String getRunningCreate() => '$running/create';
  static String getRunning() => '$running';
  static String getChatRoom(String chatRoomId) => '$chat/$chatRoomId';
  static String getProfileMe() => '$profile/me';
  
  // WebSocket URL 생성 메서드
  static String getWebSocketUrl() {
    return baseUrl.replaceFirst('http://', 'ws://');
  }
} 