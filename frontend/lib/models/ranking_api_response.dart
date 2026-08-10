import 'package:client/models/ranking_info.dart';

import 'my_ranking_info.dart';

class RankingApiResponse {
  final List<MyRankingInfo> myRankings;
  final Map<String, List<RankingInfo>> topRankingsByCategory;

  RankingApiResponse({
    required this.myRankings,
    required this.topRankingsByCategory,
  });

  // JSON Map을 RankingApiResponse 객체로 변환하는 팩토리 생성자
  factory RankingApiResponse.fromJson(Map<String, dynamic> json) {
    final topRankingsMap = (json['topRankingsByCategory'] as Map<String, dynamic>).map(
          (category, rankersJson) {
        final rankersList = (rankersJson as List)
            .map((rankerJson) => RankingInfo.fromJson(rankerJson))
            .toList();
        return MapEntry(category, rankersList);
      },
    );

    return RankingApiResponse(
      // myRankings 필드는 List<dynamic> 이므로, 각 요소를 MyRankingInfo 객체로 변환합니다.
      myRankings: (json['myRankings'] as List)
          .map((item) => MyRankingInfo.fromJson(item))
          .toList(),
      topRankingsByCategory: topRankingsMap,
    );
  }
}