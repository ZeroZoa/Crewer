import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/custom_app_bar.dart';
import '../components/login_modal_screen.dart';
import '../config/api_config.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 수정한 부분: 변수 이름을 API 응답과 일치시켰습니다.
  List<dynamic> _hotGroupFeeds = [];
  List<dynamic> _hotFeeds = [];
  List<dynamic> _groupFeeds = [];
  String? _error;
  bool _isLoading = true; // 수정한 부분: 초기 상태를 true로 변경
  bool isDropdownOpen = false;
  //final ScrollController _scrollController = ScrollController();

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // 수정한 부분: initState에서 직접 비동기 호출을 피하고, token을 먼저 가져오도록 구조 변경
    _initializeScreen();
  }

  // 수정한 부분: 초기화 로직을 별도 메서드로 분리
  Future<void> _initializeScreen() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      // 토큰이 없으면 로그인 모달 바로 띄우기
      if (mounted) {
        final newToken = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          builder: (_) => LoginModalScreen(),
        );
        if (newToken != null) {
          await _loadAllData(newToken);
        } else {
          if (mounted) context.pop(); // 로그인 안하면 이전 화면으로
        }
      }
    } else {
      await _loadAllData(token);
    }
  }

  // 개선된 부분: API 응답이 Page<> 형식이므로, content를 추출하도록 수정
  Future<List<dynamic>> _fetchCloseToDeadlineGroupFeeds(String token) async {
    final resp = await http.get(
      Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.getCloseToDeadlineGroupFeeds()}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      // 수정한 부분: Spring의 Page<> 객체는 'content' 필드에 리스트를 담고 있습니다.
      return json.decode(utf8.decode(resp.bodyBytes))['content'] as List<dynamic>;
    } else {
      throw Exception('마감 임박 크루 로딩 실패: Status Code ${resp.statusCode}');
    }
  }

  Future<List<dynamic>> _fetchHotFeeds(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getHotFeedForMain()}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes))['content'] as List<dynamic>;
    } else {
      throw Exception('인기 피드 로딩 실패: Status Code ${response.statusCode}');
    }
  }

  Future<List<dynamic>> _fetchRecruitingGroupFeeds(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedsForMain()}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    } else {
      throw Exception('크루원 구해요 로딩 실패: Status Code ${response.statusCode}');
    }
  }


  Future<void> _loadAllData(String token) async {
    // 개선된 부분: 이미 로딩 중이면 중복 호출 방지
    if (!mounted || _isLoading && _hotGroupFeeds.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _fetchHotFeeds(token),
        _fetchCloseToDeadlineGroupFeeds(token),
        _fetchRecruitingGroupFeeds(token)
      ]);
      setState(() {
        // 수정한 부분: Future.wait의 결과 순서에 맞게 변수를 할당해야 합니다. (치명적인 버그 수정)
        _hotFeeds = results[0];
        _hotGroupFeeds = results[1];
        _groupFeeds = results[2];
        _isLoading = false; // 로딩 완료
      });
    } catch (e) {
      // 401 (Unauthorized), 403 (Forbidden) 에러 처리
      if (e.toString().contains('401') || e.toString().contains('403')) {
        if (mounted) {
          final newToken = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            builder: (_) => LoginModalScreen(),
          );

          if (newToken != null) {
            await _loadAllData(newToken);
          } else {
            if (mounted) context.pop();
          }
        }
      } else {
        setState(() {
          _error = "데이터를 불러오는 데 실패했습니다: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateIfLoggedIn(String route) async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      LoginModalScreen();
    } else {
      context.push(route);
    }
  }

  void _toggleDropdown() => setState(() => isDropdownOpen = !isDropdownOpen);

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);

    return DateFormat('MM/dd HH:mm').format(d);
  }


  Widget _buildGroupFeedCard(Map<String, dynamic> _hotGroupFeeds) {
    final maxParticipants = _hotGroupFeeds['maxParticipants'] ?? 2;
    final currentParticipants = _hotGroupFeeds['currentParticipants'] ?? 1;
    final remainingParticipants = maxParticipants - currentParticipants; // 이제 이 계산은 절대 null 때문에 에러가 나지 않습니다.

    return AspectRatio(
      aspectRatio: 1 / 0.6,
      child: InkWell(
        onTap: () {
          context.push('/groupfeeds/${_hotGroupFeeds['id']}');
        },
        borderRadius: BorderRadius.circular(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(158, 158, 158, 0.2), // Colors.grey.withOpacity(0.2) 대체
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF002B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$remainingParticipants명 남았어요!',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(height: 4,),
                  SizedBox(
                    height: 60,
                    child: Text(
                      _hotGroupFeeds['title'],
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    // Row의 정렬을 가운데로 맞추고 싶다면 추가
                    mainAxisSize: MainAxisSize.min, // Row의 크기를 자식들에게 맞춤
                    children: [
                      // 1. 지도 아이콘 추가
                      Icon(
                        LucideIcons.mapPin,
                        color: Color(0xFF767676), // 텍스트와 동일한 색상
                        size: 16, // 텍스트 크기와 비슷하게 조절
                      ),
                      // 2. 아이콘과 텍스트 사이 간격
                      SizedBox(width: 6),
                      // 3. 기존 텍스트 위젯
                      Text(
                        _hotGroupFeeds['meetingPlace'],
                        style: const TextStyle(color: Color(0xFF767676), fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            )
        ),
      ),
    );
  }

  // 개선된 부분: 실제 데이터를 파라미터로 받도록 변경
  Widget _buildPopularFeedItem({required Map<String, dynamic> feed}) {
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
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
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
                      _formatDate(feed['createdAt']),
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
                            color: Colors.blue, size: 17),
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

  Widget _buildRecruitingGroupFeedItem({required Map<String, dynamic> groupFeeds}) {
    final maxParticipants = groupFeeds['maxParticipants'] ?? 2;
    return InkWell(
      onTap: () {
        context.push('/groupfeeds/${groupFeeds['id']}');
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
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
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
                        '${groupFeeds['authorNickname'] ?? '알 수 없음'}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)
                    ),
                    Text(
                      _formatDate(groupFeeds['createdAt']),
                      style:
                      TextStyle(color: Color(0xFF767676), fontSize: 11),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(groupFeeds['title'], style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$maxParticipants명 모집중',
                      style:
                      TextStyle(color: Color(0xFFFF002B), fontSize: 12),
                    ),
                  ],
                )
              ],
            )
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        appBarType: AppBarType.main,
        leading: Padding(
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
      body: _isLoading && _hotGroupFeeds.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeScreen,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          RefreshIndicator(
            onRefresh: _initializeScreen,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 마감 임박 크루 섹션
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 30, right: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text("마감 임박 크루", style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
                        TextButton(
                          onPressed: () {
                            // 주석: '더보기'를 눌렀을 때 이동할 페이지의 경로를 지정합니다.
                            // 예를 들어, 전체 피드 목록 페이지가 '/group-feeds/all' 이라면 아래와 같이 작성합니다.
                            context.push('/groupfeeds');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFF767676),
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            // // 수정: 수직 정렬 기준을 baseline으로 변경
                            crossAxisAlignment: CrossAxisAlignment.start,
                            // // 수정: baseline의 유형을 지정 (한글이므로 ideographic)
                            //textBaseline: TextBaseline.ideographic,
                            children: [
                              Text('더보기', style: TextStyle(fontSize: 13)),
                              Icon(
                                Icons.keyboard_arrow_right_rounded,
                                size: 21.0, // 아이콘 크기는 폰트 크기와 맞춰주는 것이 보기 좋습니다.
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 170,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal:8),
                      itemCount: _hotGroupFeeds.length,
                      itemBuilder: (context, index) {
                        final hotGroupFeed = _hotGroupFeeds[index];
                        return _buildGroupFeedCard(hotGroupFeed);
                      },
                    ),
                  ),
                  // 인기피드 섹션
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 30, right: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("인기 피드", style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
                        TextButton(
                          onPressed: () {
                            context.push('/feeds');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF767676),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            // // 수정: 수직 정렬 기준을 baseline으로 변경
                            crossAxisAlignment: CrossAxisAlignment.start,
                            // // 수정: baseline의 유형을 지정 (한글이므로 ideographic)
                            //textBaseline: TextBaseline.ideographic,
                            children: [
                              Text('더보기', style: TextStyle(fontSize: 13)),
                              Icon(
                                Icons.keyboard_arrow_right_rounded,
                                size: 21.0, // 아이콘 크기는 폰트 크기와 맞춰주는 것이 보기 좋습니다.
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 4, right: 4),
                    padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                    child: Column(
                      children: [
                        // if 문을 사용하여 _hotFeeds 리스트가 비어있지 않을 경우에만 첫 번째 아이템을 보여줍니다.
                        if (_hotFeeds.isNotEmpty)
                          _buildPopularFeedItem(feed: _hotFeeds[0]),
                        // _hotFeeds 리스트의 길이가 1보다 클 경우 (즉, 아이템이 2개 이상일 경우) 두 번째 아이템을 보여줍니다.
                        if (_hotFeeds.length > 1)
                          _buildPopularFeedItem(feed: _hotFeeds[1]),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 30, right: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text("크루원 모집중!", style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
                        TextButton(
                          onPressed: () {
                            context.push('/groupfeeds');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF767676),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('더보기', style: TextStyle(fontSize: 13)),
                              Icon(
                                Icons.keyboard_arrow_right_rounded,
                                size: 21.0, // 아이콘 크기는 폰트 크기와 맞춰주는 것이 보기 좋습니다.
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                    padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                    child: Column(
                      children: [
                        if (_groupFeeds.isNotEmpty)
                          _buildRecruitingGroupFeedItem(groupFeeds: _groupFeeds[0]),
                        if (_groupFeeds.length > 1)
                          _buildRecruitingGroupFeedItem(groupFeeds: _groupFeeds[1]),
                      ],
                    ),
                  ),

                ],
              ),
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
    );
  }
}