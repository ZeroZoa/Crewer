class RankingInfo {
  final int recordId;
  final int runnerId;
  final String runnerNickname;
  final double totalDistance;
  final int totalSeconds;
  final DateTime createdAt;
  final String distanceCategory;
  final int ranking;

  RankingInfo({
    required this.recordId,
    required this.runnerId,
    required this.runnerNickname,
    required this.totalDistance,
    required this.totalSeconds,
    required this.createdAt,
    required this.distanceCategory,
    required this.ranking,
  });

  // JSON Map을 RankingInfo 객체로 변환하는 팩토리 생성자
  factory RankingInfo.fromJson(Map<String, dynamic> json) {
    return RankingInfo(
      recordId: json['recordId'],
      runnerId: json['runnerId'],
      runnerNickname: json['runnerNickname'],
      totalDistance: (json['totalDistance'] as num).toDouble(),
      totalSeconds: json['totalSeconds'],
      createdAt: DateTime.parse(json['createdAt']),
      distanceCategory: json['distanceCategory'],
      ranking: json['ranking'],
    );
  }
}