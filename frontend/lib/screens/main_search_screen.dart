import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:client/config/api_config.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainSearchScreen extends StatefulWidget {
  const MainSearchScreen({Key? key}) : super(key: key);

  @override
  State<MainSearchScreen> createState() => _MainSearchScreenState();
}

class _MainSearchScreenState extends State<MainSearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  late final TabController _tabController;

  // 상태 관리 변수
  bool _isLoading = false;
  bool _hasSearched = false;
  String _currentKeyword = '';

  // 데이터 변수
  List<dynamic> _feeds = [];
  List<dynamic> _groupFeeds = [];

  // 최근 검색어 저장 변수
  List<String> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

//최근 검색어 불러오기
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
      });
    }
  }

  //최근 검색어 저장
  Future<void> _saveRecentSearch(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList(_recentSearchesKey) ?? [];
    searches.remove(keyword);
    searches.insert(0, keyword);
    if (searches.length > 10) {
      searches = searches.sublist(0, 10);
    }
    await prefs.setStringList(_recentSearchesKey, searches);
    if (mounted) {
      setState(() {
        _recentSearches = searches;
      });
    }
  }

  //최근 검색어 삭제
  Future<void> _deleteRecentSearch(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList(_recentSearchesKey) ?? [];
    searches.remove(keyword);
    await prefs.setStringList(_recentSearchesKey, searches);
    if (mounted) {
      setState(() {
        _recentSearches = searches;
      });
    }
  }

  //최근 검색어 전체 삭제
  Future<void> _clearAllRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    if (mounted) {
      setState(() {
        _recentSearches = [];
      });
    }
  }


  Future<void> _performSearch() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    await _saveRecentSearch(keyword);
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
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.groupfeeds}${ApiConfig.mainSearch}')
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

  String cutContent(String text, int limit) {
    final singleLineText = text.replaceAll('\n', ' ');

    return singleLineText.length > limit
        ? '${singleLineText.substring(0, limit)}...'
        : singleLineText;
  }

  Widget _buildGroupFeedItem({required Map<String, dynamic> groupfeed}){
    //마감 시간 전이면 true 후이면 false
    final bool isWithinDeadline = DateTime.tryParse(groupfeed['deadline'] ?? '')?.isAfter(DateTime.now()) ?? false;

    return GestureDetector(
      onTap: () {
        final route = '/groupfeeds/${groupfeed['id']}';
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
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 2),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isWithinDeadline ? Color(0xFFFF002B) : Colors.grey,
                        ),
                      ),
                      child: isWithinDeadline
                          ? Text( // true일 경우: 'Crew 모집'
                        'Crew 모집',
                        style: TextStyle(
                          color: Color(0xFFFF002B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : Text( // false일 경우: 'Crew 마감'
                        'Crew 마감',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 6,),
                    Text(
                      cutContent(groupfeed['title'], 15),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  cutContent(groupfeed['content'], 22),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '${groupfeed['authorNickname'] ?? '알 수 없음'} | ',
                      style:
                      TextStyle(color: Colors.grey[600], fontSize: 14, ),
                    ),
                    Text(
                      getRelativeTime(groupfeed['createdAt']),
                      style:
                      TextStyle(color: Colors.grey[600], fontSize: 14, ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(LucideIcons.heart, color: Colors.red, size: 17),
                    SizedBox(width: 2),
                    Text('${groupfeed['likesCount'] ?? 0}'),
                    SizedBox(width: 10),
                    Icon(LucideIcons.messageCircle, color: Colors.grey, size: 17),
                    SizedBox(width: 3),
                    Text('${groupfeed['commentsCount'] ?? 0}'),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeedItem({required Map<String, dynamic> feed}){
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
                    Text(
                      cutContent(feed['title'], 15),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  cutContent(feed['content'], 22),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '${feed['authorNickname'] ?? '알 수 없음'} | ',
                      style:
                      TextStyle(color: Colors.grey[600], fontSize: 14, ),
                    ),
                    Text(
                      getRelativeTime(feed['createdAt']),
                      style:
                      TextStyle(color: Colors.grey[600], fontSize: 14, ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(LucideIcons.heart, color: Colors.red, size: 17),
                    SizedBox(width: 2),
                    Text('${feed['likesCount'] ?? 0}'),
                    SizedBox(width: 10),
                    Icon(LucideIcons.messageCircle, color: Colors.grey, size: 17),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasSearched
          ? Column(
            children: [
              _buildRecentSearches(),
              Expanded(
                child: Center(
                  child: Text(
                    '검색어를 입력해주세요.',
                    style: TextStyle(color: Colors.grey, fontSize: 20),
                  ),
                ),
              ),
            ],
          )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildFeedResultList(),    // 첫 번째 탭: 피드 결과
          _buildGroupFeedResultList(), // 두 번째 탭: 그룹 피드 결과
        ],
      ),
    );
  }


  // 피드 결과 탭 UI
  Widget _buildFeedResultList() {
    // 수정한 부분: 여러 위젯을 세로로 배치하기 위해 Column으로 감쌉니다.
    return Column(
      children: [
        _buildRecentSearches(),
        Expanded(
          child: _feeds.isEmpty
              ? const Center( // 검색 결과가 없을 때
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
                children: [
                  Icon(LucideIcons.fileQuestion, color: Colors.grey, size: 100),
                  SizedBox(height: 20),
                  Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 20)),
                ],
              ))
              : ListView.separated( // 검색 결과가 있을 때
            padding: const EdgeInsets.all(16),
            itemCount: _feeds.length,
            separatorBuilder: (context, index) => Divider(
              thickness: 1,
              color: Colors.grey[300],
            ),
            itemBuilder: (context, index) {
              // 이미 위에서 feed 변수를 선언했으므로 사용합니다.
              final feed = _feeds[index];
              return _buildFeedItem(feed: feed);
            },
          ),
        ),
      ],
    );
  }

  // 그룹 피드 결과 탭 UI
  Widget _buildGroupFeedResultList() {
    return Column(
      children: [
        _buildRecentSearches(),
        Expanded(
          child: _groupFeeds.isEmpty
              ? const Center( // 검색 결과가 없을 때
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.fileQuestion, color: Colors.grey, size: 100),
                  SizedBox(height: 20),
                  Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 20)),
                ],
              ))
              : ListView.separated( // 검색 결과가 있을 때
            padding: const EdgeInsets.all(16.0),
            itemCount: _groupFeeds.length,
            separatorBuilder: (context, index) => Divider(
              thickness: 1,
              color: Colors.grey[300],
            ),
            itemBuilder: (context, index) {
              final groupFeed = _groupFeeds[index];
              // groupFeed 변수를 사용하도록 수정했습니다.
              return _buildGroupFeedItem(groupfeed: groupFeed);
            },
          ),
        ),
      ],
    );
  }

  //최근 검색 결과
  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 8,top: 8, right: 8,bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Text('최근 검색어', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            SizedBox(
              child: Center(
                child: Text(
                  '최근 검색 기록이 없습니다.',
                  style: TextStyle(color: Colors.grey, fontSize: 20),
                ),
              ),
            ),
          ],
        )
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('최근 검색어', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _clearAllRecentSearches,
                child: const Text('전체 삭제', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 50.0, // 가로 목록의 높이를 원하는 대로 조절하세요.
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final keyword = _recentSearches[index];
              // 수정한 부분: 각 항목을 Chip 형태로 만듭니다.
              return Padding(
                padding: const EdgeInsets.only(right: 8.0), // 각 칩 사이의 간격
                child: InputChip(
                  label: Text(keyword, style: TextStyle(color:Colors.grey[600])),
                  // 칩을 눌렀을 때의 동작
                  onPressed: () {
                    _searchController.text = keyword;
                    _performSearch();
                  },
                  // 삭제 아이콘을 눌렀을 때의 동작
                  onDeleted: () => _deleteRecentSearch(keyword),
                  // 칩 스타일링 (선택 사항)
                  backgroundColor: Color(0xFFFAFAFA),
                  deleteIconColor: Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}