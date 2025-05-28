import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP 요청
import 'dart:convert'; // JSON 변환
import 'package:lucide_icons/lucide_icons.dart';
import 'package:client/components/top_navbar.dart'; // 상단 네비게이션바
import 'package:client/components/bottom_navbar.dart'; // 하단 네비게이션바

/// 그룹 피드 상세 화면
/// feedId: 조회할 그룹 피드 ID
class GroupFeedDetailScreen extends StatefulWidget {
  final String feedId;
  const GroupFeedDetailScreen({Key? key, required this.feedId}) : super(key: key);

  @override
  _GroupFeedDetailScreenState createState() => _GroupFeedDetailScreenState();
}

class _GroupFeedDetailScreenState extends State<GroupFeedDetailScreen> {
  Map<String, dynamic>? _feed;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  /// 서버에서 그룹 피드 상세 정보를 가져옵니다.
  Future<void> _fetchDetail() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/groupfeeds/${widget.feedId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _feed = json.decode(response.body);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  /// ISO 형식 날짜를 YYYY년 M월 D일로 변환합니다.
  String _formatDate(String iso) {
    final date = DateTime.parse(iso);
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(
        onBack: () => Navigator.pop(context), // 뒤로가기 처리
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error || _feed == null
          ? const Center(child: Text('그룹 피드를 불러오지 못했습니다.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 그룹 태그 (# 모여요)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF9CB4CD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '# 모여요',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            // 제목
            Text(
              _feed!['title'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // 작성자 · 날짜
            Text(
              '${_feed!['authorNickname'] ?? '알 수 없음'} · ${_formatDate(_feed!['createdAt'])}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            // 본문 내용
            Text(
              _feed!['content'] ?? '',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            // 좋아요 · 댓글 수
            Row(
              children: [
                const Icon(LucideIcons.heart, color: Colors.red, size: 20),
                const SizedBox(width: 4),
                Text('${_feed!['likesCount'] ?? 0}'),
                const SizedBox(width: 16),
                const Icon(LucideIcons.messageCircle, color: Colors.blue, size: 20),
                const SizedBox(width: 4),
                Text('${_feed!['commentsCount'] ?? 0}'),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
