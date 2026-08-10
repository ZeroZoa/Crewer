import 'package:flutter/material.dart';
import '../components/custom_app_bar.dart';
import '../models/my_ranking_info.dart';
import '../models/ranking_info.dart';

class RankingDetailScreen extends StatelessWidget {
  final String category;
  final MyRankingInfo? myRankInfo;
  final List<RankingInfo> topRankings;

  const RankingDetailScreen({
    super.key,
    required this.category,
    this.myRankInfo,
    required this.topRankings,
  });

  // RankingScreen에서 사용하던 pace 포맷 함수를 가져옵니다.
  String _formatPace(double totalDistance, int totalSeconds) {
    if (totalDistance < 1) return "-'--\"";
    double paceInSecondsPerKm = totalSeconds / (totalDistance / 1000);
    int minutes = paceInSecondsPerKm ~/ 60;
    int seconds = (paceInSecondsPerKm % 60).round();
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarType: AppBarType.back,
        title: Text(
          category,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        actions: [],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // 나의 랭킹 정보 표시
          _buildMyRankHighlight(context),
          const SizedBox(height: 24),
          // 전체 랭킹 리스트
          Expanded(
            child: Container(
              color: const Color(0xFFF1F1F1),
              child: topRankings.isEmpty
                  ? const Center(child: Text('랭킹 기록이 없습니다.'))
                  : ListView.builder(
                itemCount: topRankings.length,
                itemBuilder: (context, index) {
                  final ranker = topRankings[index];
                  // 나의 랭킹인 경우 하이라이트 처리
                  final bool isMe = myRankInfo?.myRecord.runnerId == ranker.runnerId;
                  return _buildRankerTile(ranker, isMe, context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 나의 랭킹을 상단에 강조해서 보여주는 위젯
  Widget _buildMyRankHighlight(BuildContext context) {

    if (myRankInfo == null) {
      // 해당 카테고리에 나의 기록이 없는 경우
      return Card(
        elevation: 0,
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text('이 거리에서의 기록이 없습니다.'),
          ),
        ),
      );
    }

    final myRecord = myRankInfo!.myRecord;

    return Center(
      child: Column(
        children: [
          Text(
              '${myRankInfo!.myRank}위',
              style: TextStyle(fontSize: 26, color: Colors.black, fontWeight: FontWeight.w500)
          ),
          Text(
              '${myRecord.runnerNickname}님은 ',
              style: TextStyle(fontSize: 18, color: Color(0xFF767676), )
          ),
          Text(
              'Crewer에서',
              style: TextStyle(fontSize: 18, color: Color(0xFF767676), )
          ),
          Text(
              '상위 ${myRankInfo!.percentile.toStringAsFixed(0)}% 입니다. ',
              style: TextStyle(fontSize: 18, color: Color(0xFF767676), )
          ),
        ],
      )
    );
  }

  // 개별 랭커 정보를 보여주는 리스트 타일 위젯
  Widget _buildRankerTile(RankingInfo ranker, bool isMe, BuildContext context) {
    final pace = _formatPace(ranker.totalDistance, ranker.totalSeconds);
    return Container(
      //margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFDCDCDC) : Colors.transparent, // 나인 경우 배경색 강조
      ),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Text(
            '${ranker.ranking}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: ranker.ranking <= 3 ? const Color(0xFFFF002B) : Colors.black87, // Top 3 색상 강조
            ),
          ),
        ),
        title: Text(
          ranker.runnerNickname,
          style: TextStyle(
            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Text(
          pace,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}