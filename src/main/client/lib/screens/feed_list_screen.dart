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
  bool isnewSelected = false;

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    _fetchPopularFeeds();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent &&
          hasMore &&
          !loading) {
        page++;
        _fetchPopularFeeds();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPopularFeeds() async {
    setState(() => loading = true);
    feeds.clear();
    page = 0;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getFeedListPopular()}?page=$page&size=20'),
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
      setState(() {
        loading = false;
        isnewSelected = false;
      });
    }
  }


  Future<void> _fetchNewFeeds() async {
    setState(() => loading = true);
    feeds.clear();
    page = 0;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getFeedListNew()}?page=$page&size=20'),
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
      setState((){
        loading = false;
        isnewSelected = true;
      });
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
    await _fetchPopularFeeds();
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
    bottom: 80,
    right: 20,
    child: Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2D42),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined, color: Colors.white),
              title: const Text('피드 글 쓰기', style: TextStyle(color: Colors.white)),
              onTap: () => _navigateIfLoggedIn('/feeds/create'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.users, color: Colors.white),
              title: const Text('그룹 피드 글 쓰기', style: TextStyle(color: Colors.white)),
              onTap: () => _navigateIfLoggedIn('/groupfeeds/create'),
            ),
          ],
        ),
      ),
    ),
  );

  String getRelativeTime(String isoTimeString) {
    if (isoTimeString.isEmpty){
      return '';
    }
    try{DateTime sentTime = DateTime.parse(isoTimeString).toLocal(); // UTC → local
    DateTime now = DateTime.now();
    Duration diff = now.difference(sentTime);

    if (diff.inSeconds < 60) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';

    // 일주일 넘으면 날짜로 표시
    return '${sentTime.year}.${sentTime.month.toString().padLeft(2, '0')}.${sentTime.day.toString().padLeft(2, '0')}';}
    catch(e){return '';}

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CustomAppBar(
        appBarType: AppBarType.back,
        title: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 0, top: 4),
          child: const Text(
            '피드',
            style: TextStyle(
              color: Color(0xFF111111),
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        ),
        actions: [],
      ),      
      backgroundColor: Color(0xFFFAFAFA),
      body: Column(        
        children: [
          SizedBox(height: 20,),
          Row(
            children: [
              SizedBox(width: 15),
              ElevatedButton(
                  onPressed: () => _fetchPopularFeeds(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: !isnewSelected ? Color(0xFFFF002B): Colors.white,
                      foregroundColor:!isnewSelected ? Colors.white: Colors.grey,
                      elevation: 0,
                      side: BorderSide(
                          color: !isnewSelected ? Colors.white:Colors.grey
                      )
                  ),
                  child: Text("인기순")),
              SizedBox(width: 10),
              ElevatedButton(
                  onPressed:() => _fetchNewFeeds(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isnewSelected ? Color(0xFFFF002B): Colors.white,
                      foregroundColor: isnewSelected ? Colors.white: Colors.grey,
                      elevation: 0,
                      side: BorderSide(
                          color: isnewSelected ? Colors.white:Colors.grey
                      )
                  ),
                  child: Text("최신순")),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: Colors.white,                     // 로딩 아이콘의 색상
                  backgroundColor: Color(0xFFFF002B),      // 로딩 아이콘의 배경색
                  strokeWidth: 3.0,                        // 로딩 아이콘 선의 두께
                  displacement: 30.0,                      // 화면 상단에서 얼마나 떨어져서 보일지
                  elevation: 0,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    padding: EdgeInsets.all(10),
                    itemCount: feeds.length + (hasMore ? 1 : 0),
                    separatorBuilder: (context, index) => Divider(thickness: 1,),
                    itemBuilder: (ctx, idx) {
                      if (idx == feeds.length) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final feed = feeds[idx];
                      return GestureDetector(
                        onTap: () {
                          final route = '/feeds/${feed['id']}';
                          context.push(route);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Visibility(
                                        visible: !isnewSelected,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric( horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(                                                
                                                border: Border.all(color: Color(0xFFDBDBDB)),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                'HOT',
                                                style: TextStyle(
                                                    color: Color(0xFFFF002B), fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            SizedBox(width: 5),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _truncate(feed['title']),
                                        style: TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _truncate(feed['content']),
                                    style: TextStyle(
                                        fontSize: 15),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${feed['authorNickname'] ?? '알 수 없음'} | ',
                                        style:
                                        TextStyle(color: Colors.grey.shade800, fontSize: 15),
                                      ),
                                      Text(
                                        getRelativeTime(feed['createdAt']),
                                        style:
                                        TextStyle(color: Colors.grey.shade800, fontSize: 15),
                                      ),

                                    ],
                                  ),
                                  Row(
                                    children: [ Icon(LucideIcons.heart,
                                        color: Colors.red, size: 17),
                                      SizedBox(width: 2),
                                      Text('${feed['likesCount'] ?? 0}'),
                                      SizedBox(width: 10),
                                      Icon(LucideIcons.messageCircle,
                                          color: Colors.grey, size: 17),
                                      SizedBox(width: 3),
                                      Text('${feed['commentsCount'] ?? 0}'),],
                                  ),

                                ],
                              ),
                              Spacer(),
                              Container(  //이미지 넣을 곳
                                width: 70,
                                height: 70,
                                color: Colors.grey.shade200,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (isDropdownOpen) _buildDropdownMenu(),
                Positioned(
                  bottom: 10,
                  right: 20,
                  child: GestureDetector(
                    onTap: _toggleDropdown,
                    child: Container(
                      width: 64, // 너비
                      height: 64, // 높이
                      decoration: BoxDecoration(
                        color: isDropdownOpen ? Color(0xFF2B2D42) : Color(0xFFFF002B),
                        shape: BoxShape.circle, // 모양을 원으로 지정
                        // border: Border.all(color: isDropdownOpen ? Color(0xFF2B2D42) : Color(0xFFFF002B), width: 4),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: Center(
                        child: Icon(
                          isDropdownOpen ? LucideIcons.x : LucideIcons.plus,
                          size: 36, // 아이콘 크기
                          color: Colors.white, // 아이콘 색상
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}