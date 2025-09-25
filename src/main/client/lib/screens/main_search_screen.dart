import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:client/config/api_config.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MainSearchScreen extends StatefulWidget {
  const MainSearchScreen({Key? key}) : super(key: key);

  @override
  State<MainSearchScreen> createState() => _MainSearchScreenState();
}

// 수정: TabController를 사용하기 위해 TickerProviderStateMixin을 추가합니다.
class _MainSearchScreenState extends State<MainSearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  // 수정: TabController를 상태 변수로 추가합니다.
  late final TabController _tabController;

  // 상태 관리 변수 (기존 로직 그대로 유지)
  bool _isLoading = false;
  bool _hasSearched = false;
  String _currentKeyword = '';

  // 데이터 변수 (기존 로직 그대로 유지)
  List<dynamic> _feeds = [];
  List<dynamic> _groupFeeds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose(); // 수정: TabController를 dispose합니다.
    super.dispose();
  }


  Future<void> _performSearch() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _currentKeyword = keyword;
      _feeds = [];
      _groupFeeds = [];
    });

    await Future.wait([
      _fetchFeeds(keyword, 0),
      _fetchGroupFeeds(keyword, 0),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchFeeds(String keyword, int page) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.feeds}${ApiConfig.mainSearch}')
          .replace(queryParameters: {'keyword': keyword, 'page': '$page', 'size': '20'});
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _feeds.addAll(data['content']);
          });
        }
      }
    } catch (e) {
      // 에러 처리
    }
  }

  Future<void> _fetchGroupFeeds(String keyword, int page) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.groupFeeds}${ApiConfig.mainSearch}')
          .replace(queryParameters: {'keyword': keyword, 'page': '$page', 'size': '20'});
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _groupFeeds.addAll(data['content']);
          });
        }
      }
    } catch (e) {
      // 에러 처리
    }
  }

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

  Widget _buildGroupFeedItem({required Map<String, dynamic> groupfeed}){
    final remainingParticipants = (groupfeed['maxParticipants'] ?? 0) - (groupfeed['currentParticipants'] ?? 0);
    final deadline = DateTime.parse(groupfeed['deadline'] ?? DateTime.now().toIso8601String());
    final bool isDeadlinePassed = deadline.isBefore(DateTime.now());

    return InkWell(
      onTap: () {
        context.push('/groupfeeds/${groupfeed['id']}');
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(158, 158, 158, 0.2), // Colors.grey.withOpacity(0.2) 대체
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${groupfeed['authorNickname'] ?? '알 수 없음'}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)
                    ),
                    Text(
                      getRelativeTime(groupfeed['createdAt']),
                      style:
                      TextStyle(color: Color(0xFF767676), fontSize: 11),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(groupfeed['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDeadlinePassed ? '마감했습니다' : '$remainingParticipants명 모집중',
                      style: TextStyle(
                        color: isDeadlinePassed ? Colors.grey.shade600 : Color(0xFFFF002B),
                        fontSize: 12,
                        fontWeight: isDeadlinePassed ? FontWeight.normal : FontWeight.bold, // 스타일도 조건부로 적용
                      ),
                    ),
                  ],
                )
              ],
            )
        ),
      ),
    );
  }

  Widget _buildFeedItem({required Map<String, dynamic> feed}){
    return InkWell(
      onTap: () {
        context.push('/feeds/${feed['id']}');
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(158, 158, 158, 0.2), // Colors.grey.withOpacity(0.2) 대체
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${feed['authorNickname'] ?? '알 수 없음'}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)
                    ),
                    Text(
                      getRelativeTime(feed['createdAt']),
                      style:
                      TextStyle(color: Color(0xFF767676), fontSize: 11),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(feed['title'], style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      feed['content'],
                      style:
                      TextStyle(color: Colors.grey.shade800, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                            color: Colors.grey, size: 17),
                        SizedBox(width: 3),
                        Text('${feed['commentsCount'] ?? 0}'),
                      ],
                    ),
                  ],
                )
              ],
            )
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0.0,
        title: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4, right: 16.0),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onSubmitted: (_) => _performSearch(),
            decoration: InputDecoration(
              hintText: '작성자, 제목, 내용 검색',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.red),
                onPressed: _performSearch,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade200,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            ),
          ),
        ),
        // 수정: TabBar를 AppBar의 bottom 속성에 추가합니다.
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '피드'),
            Tab(text: '그룹 피드'),
          ],
          labelColor: Color(0xFFFF002B),
          unselectedLabelColor: Color(0xFFBDBDBD),
          indicatorColor: Color(0xFFFF002B),
        ),
      ),
      // 수정: body 부분을 TabBarView로 변경합니다.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasSearched
          ? const Center(child: Text('검색어를 입력해주세요.', style: TextStyle(color: Colors.grey, fontSize: 20)))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildFeedResultList(),    // 첫 번째 탭: 피드 결과
          _buildGroupFeedResultList(), // 두 번째 탭: 그룹 피드 결과
        ],
      ),
    );
  }

  // 수정: _buildResultView를 두 개의 메소드로 분리합니다.

  // 피드 결과 탭 UI
  Widget _buildFeedResultList() {
    if (_feeds.isEmpty) {
      return const Center(
          child: Column(
            children: [
              SizedBox(height: 60),
              Icon(LucideIcons.fileQuestion, color: Colors.grey, size: 100),
              SizedBox(height: 20),
              Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 20))
            ],
          )

      );
    }
    // 이제 각 탭이 독립된 스크롤을 가지므로 SingleChildScrollView가 필요 없습니다.
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: _feeds.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8,),
      itemBuilder: (context, index) {
        final feed = _feeds[index];
        return _buildFeedItem(feed: _feeds[index]);
      },
    );
  }

  // 그룹 피드 결과 탭 UI
  Widget _buildGroupFeedResultList() {
    if (_groupFeeds.isEmpty) {
      return const Center(
          child: Column(
            children: [
              SizedBox(height: 60),
              Icon(LucideIcons.fileQuestion, color: Colors.grey, size: 100),
              SizedBox(height: 20),
              Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 20))
            ],
          )

      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _groupFeeds.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8,),
      itemBuilder: (context, index) {
        final groupFeed = _groupFeeds[index];
        return _buildGroupFeedItem(groupfeed: _groupFeeds[index]);
      },
    );
  }
}