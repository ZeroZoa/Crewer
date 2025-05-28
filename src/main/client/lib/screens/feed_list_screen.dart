import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP 요청/응답 처리
import 'dart:convert'; // JSON ↔ Dart 변환
import 'package:lucide_icons/lucide_icons.dart';
import 'package:client/components/top_navbar.dart'; // 상단 네비게이션바 컴포넌트
import 'package:client/components/bottom_navbar.dart'; // 하단 네비게이션바 컴포넌트

/// 피드 리스트 화면
class FeedListScreen extends StatefulWidget {
  @override
  _FeedListScreenState createState() => _FeedListScreenState();
}

class _FeedListScreenState extends State<FeedListScreen> {
  List<dynamic> feeds = [];                  // 피드 데이터
  int page = 0;                              // 페이지 번호
  bool hasMore = true;                       // 추가 로드 플래그
  bool loading = false;                      // 로딩 상태
  bool isDropdownOpen = false;               // 플로팅 버튼 드롭다운 상태
  final ScrollController _scrollController = ScrollController(); // 스크롤 제어기

  @override
  void initState() {
    super.initState();
    _fetchFeeds();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent &&
          hasMore &&
          !loading) {
        page++;
        _fetchFeeds();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 피드 요청
  Future<void> _fetchFeeds() async {
    setState(() => loading = true);
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/feeds?page=$page&size=20'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> fetched = data['content'] ?? [];
        if (fetched.length < 20) hasMore = false;
        setState(() => feeds.addAll(fetched));
      } else {
        print('Error fetching feeds: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching feeds: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  // 플로팅 버튼 드롭다운 토글
  void _toggleDropdown() => setState(() => isDropdownOpen = !isDropdownOpen);

  // 제목 자르기
  String _truncate(String text) =>
      text.length > 15 ? text.substring(0, 15) + '...' : text;

  // 날짜 포맷팅
  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    return '${d.year}년 ${d.month}월 ${d.day}일';
  }

  // 드롭다운 메뉴
  Widget _buildDropdownMenu() => Positioned(
    bottom: 90,
    right: 20,
    child: Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 180,
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF9CB4CD), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Icon(LucideIcons.user),
              title: Text('글 쓰기'),
              onTap: () => Navigator.pushNamed(context, '/feeds/create'),
            ),
            ListTile(
              leading: Icon(LucideIcons.users),
              title: Text('모임 글 쓰기'),
              onTap: () => Navigator.pushNamed(context, '/groupfeeds/create'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 네비게이션바: 로그인 버튼과 뒤로가기 자동 처리
      appBar: TopNavBar(onBack: () => Navigator.pop(context)),
      body: Stack(
        children: [
          // 그라데이션 배경 + 리스트
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xffd3e3e4), Color(0xff8097b5), Color(0xffd3e3e4)],
              ),
            ),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: feeds.length + (hasMore ? 1 : 0),
              itemBuilder: (ctx, idx) {
                if (idx == feeds.length) {
                  return Center(child: CircularProgressIndicator());
                }
                final feed = feeds[idx];
                final isGroup = feed.containsKey('chatRoomId');
                return GestureDetector(
                  onTap: () {
                    final route = isGroup
                        ? '/groupfeeds/${feed['id']}'
                        : '/feeds/${feed['id']}';
                    Navigator.pushNamed(context, route);
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _truncate(feed['title']),
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              if (isGroup)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Color(0xFF9CB4CD),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text('# 모여요',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14)),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${_formatDate(feed['createdAt'])} · ${feed['authorNickname'] ?? '알 수 없음'}',
                            style: TextStyle(
                                color: Colors.grey.shade800, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(LucideIcons.heart,
                                  color: Colors.red, size: 17),
                              SizedBox(width: 3),
                              Text('${feed['likesCount'] ?? 0}'),
                              SizedBox(width: 12),
                              Icon(LucideIcons.messageCircle,
                                  color: Colors.blue, size: 17),
                              SizedBox(width: 3),
                              Text('${feed['commentsCount'] ?? 0}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // 드롭다운 메뉴
          if (isDropdownOpen) _buildDropdownMenu(),
          // 플로팅 버튼
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: _toggleDropdown,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF9CB4CD), width: 4),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                child: Center(
                    child: Icon(
                      isDropdownOpen ? LucideIcons.x : LucideIcons.plus,
                      size: 32,
                      color: Color(0xFF9CB4CD),
                    )),
              ),
            ),
          ),
        ],
      ),
      // 하단 네비게이션바 컴포넌트 사용
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
