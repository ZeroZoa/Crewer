import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/custom_app_bar.dart';
import '../components/login_modal_screen.dart';
import '../config/api_config.dart';

/// 피드 리스트 화면
class FeedListScreen extends StatefulWidget {
  @override
  _FeedListScreenState createState() => _FeedListScreenState();
}

class _FeedListScreenState extends State<FeedListScreen> {
  List<dynamic> feeds = [];
  int page = 0;
  bool hasMore = true;
  bool loading = false;
  bool isDropdownOpen = false;

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();


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

  Future<void> _fetchFeeds() async {
    setState(() => loading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.feeds}?page=$page&size=20'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> fetched = data['content'] ?? [];
        if (fetched.length < 20) hasMore = false;
        setState(() => feeds.addAll(fetched));
      }
    } catch (e) {
      print('Error fetching feeds: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    // 기존 피드 리스트를 비웁니다.
    feeds.clear();
    // 페이지 번호를 초기화합니다.
    page = 0;
    // 더 많은 데이터가 있다고 플래그를 다시 설정합니다.
    hasMore = true;
    // 첫 페이지 데이터를 다시 불러옵니다.
    await _fetchFeeds();
  }

  void _toggleDropdown() => setState(() => isDropdownOpen = !isDropdownOpen);

  String _truncate(String text) =>
      text.length > 13 ? text.substring(0, 13) + '...' : text;

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    return '${d.year}년 ${d.month}월 ${d.day}일';
  }

  Future<void> _navigateIfLoggedIn(String route) async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      _showLoginModal();
    } else {
      context.push(route);
    }
  }

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginModalScreen(),
    );
  }

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
              onTap: () => _navigateIfLoggedIn('/feeds/create'),
            ),
            ListTile(
              leading: Icon(LucideIcons.users),
              title: Text('모임 글 쓰기'),
              onTap: () => _navigateIfLoggedIn('/groupfeeds/create'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarType: AppBarType.main,
        leading: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 20.0, top: 2),
          child: const Text(
            'Crewer',
            style: TextStyle(
              color: Color(0xFFFF002B),
              fontWeight: FontWeight.w600,
              fontSize: 27,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.white,                     // 로딩 아이콘의 색상
            backgroundColor: Color(0xFF9CB4CD),      // 로딩 아이콘의 배경색
            strokeWidth: 3.0,                        // 로딩 아이콘 선의 두께
            displacement: 30.0,                      // 화면 상단에서 얼마나 떨어져서 보일지
            elevation: 0,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: feeds.length + (hasMore ? 1 : 0),
              separatorBuilder: (context, index) => Divider(thickness: 1,),
              itemBuilder: (context, index) {
                if (index == feeds.length) {
                  return Center(child: CircularProgressIndicator());
                }
                final feed = feeds[index];
                final isGroup = feed.containsKey('chatRoomId');
                return GestureDetector(
                  onTap: () {
                    final route = isGroup
                        ? '/groupfeeds/${feed['id']}'
                        : '/feeds/${feed['id']}';
                    context.push(route);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _truncate(feed['title']),
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (isGroup)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(0xFF9CB4CD),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '# 모여요',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_formatDate(feed['createdAt'])} · ${feed['authorNickname'] ?? '알 수 없음'}',
                              style:
                              TextStyle(color: Colors.grey.shade800, fontSize: 12),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(LucideIcons.heart,
                                    color: Colors.red, size: 17),
                                SizedBox(width: 2),
                                Text('${feed['likesCount'] ?? 0}'),
                                SizedBox(width: 10),
                                Icon(LucideIcons.messageCircle,
                                    color: Colors.blue, size: 17),
                                SizedBox(width: 3),
                                Text('${feed['commentsCount'] ?? 0}'),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (isDropdownOpen) _buildDropdownMenu(),
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
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: Center(
                  child: Icon(
                    isDropdownOpen ? LucideIcons.x : LucideIcons.plus,
                    size: 32,
                    color: Color(0xFF9CB4CD),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}