import 'package:client/models/ranking_info.dart';

class MyRankingInfo {
  final String distanceCategory;
  final int myRank;
  final int totalRankedCount;
  final double percentile;
  final RankingInfo myRecord; // 나의 상세 기록 정보를 포함

  MyRankingInfo({
    required this.distanceCategory,
    required this.myRank,
    required this.totalRankedCount,
    required this.percentile,
    required this.myRecord,
  });

  // JSON Map을 MyRankingInfo 객체로 변환하는 팩토리 생성자
  factory MyRankingInfo.fromJson(Map<String, dynamic> json) {
    return MyRankingInfo(
      distanceCategory: json['distanceCategory'],
      myRank: json['myRank'],
      totalRankedCount: json['totalRankedCount'],
      percentile: (json['percentile'] as num).toDouble(),
      myRecord: RankingInfo.fromJson(json['myRecord']),
    );
  }
}