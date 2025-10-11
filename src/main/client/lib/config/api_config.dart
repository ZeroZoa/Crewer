class ApiConfig {
  // 개발 환경에서는 실제 컴퓨터의 IP 주소를 사용
  // 모바일에서 접근할 때는 localhost 대신 실제 IP 주소 사용

  static const String baseUrl = 'http://localhost:8080';

  // API 엔드포인트들
  static const String main = '/';
  static const String members = '/members';
  static const String feeds = '/feeds';
  static const String groupfeeds = '/groupfeeds';
  static const String mainSearch = '/mainsearch';
  static const String running = '/running';
  static const String ranking = '/running/ranking';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String directChat = '/directChat';
  static const String ws = '/ws';
  static const String notifications = '/notifications';

  static String getLogin() => '$members/login';
  static String getSignup() => '$members/register';
  static String getSendVerificationCode() => '$members/send-verification-code';
  static String getVerifyCode() => '$members/verify-code';


  // 편의 메서드들
  static String getFeedListPopular() => '$feeds/popular';
  static String getFeedListNew() => '$feeds/new';
  static String getFeedDetail(String feedId) => '$feeds/$feedId';
  static String getFeedComments(String feedId) => '$feeds/$feedId/comments';
  static String getFeedLikeStatus(String feedId) => '$feeds/$feedId/like/status';
  static String getFeedLike(String feedId) => '$feeds/$feedId/like';
  static String getFeedEdit(String feedId) => '$feeds/$feedId/edit';
  static String getFeedCreate() => '$feeds/create';
  static String getHotFeed() => '$feeds/hot';
  static String getHotFeedForMain() => '$feeds/toptwo';

  static String getGroupFeedListPopular() => '$groupfeeds/popular';
  static String getGroupFeedListNew() => '$groupfeeds/new';
  static String getGroupFeedDetail(String groupFeedId) =>
      '$groupfeeds/$groupFeedId';
  static String getGroupFeedParticipants(String groupFeedId) =>
      '$groupfeeds/$groupFeedId/participants';
  static String getGroupFeedComments(String groupFeedId) =>
      '$groupfeeds/$groupFeedId/comments';
  static String getGroupFeedLikeStatus(String groupFeedId) =>
      '$groupfeeds/$groupFeedId/like/status';
  static String getGroupFeedLike(String groupFeedId) =>
      '$groupfeeds/$groupFeedId/like';
  static String getGroupFeedJoinChat(String groupFeedId) =>
      '$groupfeeds/$groupFeedId/join-chat';
  static String getGroupFeedEdit(String groupFeedId) =>
      '$groupfeeds/$groupFeedId/edit';
  static String getGroupFeedCreate() =>
      '$groupfeeds/create';
  static String getAlmostFullGroupFeeds() =>
      '$groupfeeds/hot';
  static String getGroupFeedsForMain() =>
      '$groupfeeds/latesttwo';

  static String getDirectChat() => '$chat/getdirectchat';
  static String getGroupChat() => '$chat/getgroupchat';
  static String getJoinDirectChat(String username) => '$directChat/$username/join-chat';
  static String uploadImage() => '$chat/uploadimage';
  static String getChatRoom(String chatRoomId) => '$chat/$chatRoomId';


  static String getRunningCreate() => '$running/create';
  static String getRunning() => '$running';
  static String getRanking() => '$ranking';
  static String getProfileMe() => '$profile/me';
  static String getProfileByUsername(String username) => '$profile/$username';
  static String getUserFeeds(String username) => '$profile/$username/feeds';
  static String updateNickname() => '$profile/me/nickname';
  static String getInterestCategories() => '$profile/interests/categories';
  
  // 알림 관련 API
  static String getNotifications() => notifications;
  static String markNotificationAsRead(String notificationId) => '$notifications/$notificationId/read';
  static String getNotificationCount() => '$notifications/count';
  static String completeGroupFeed(String chatRoomId) => '$groupfeeds/chatroom/$chatRoomId/complete';
  static String submitEvaluation() => '/evaluation';

  // WebSocket URL 생성 메서드
  static String getWebSocketUrl() {
    return baseUrl.replaceFirst('http://', 'ws://');
  }
}
