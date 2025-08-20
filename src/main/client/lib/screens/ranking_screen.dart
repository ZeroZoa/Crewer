import 'package:flutter/material.dart'; // Flutter UI
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅
import 'package:intl/date_symbol_data_local.dart'; // 지역화된 날짜 포맷 초기화
import 'package:http/http.dart' as http; // HTTP 요청
import 'dart:convert'; // JSON 파싱
import 'package:go_router/go_router.dart'; // 라우팅
import 'package:table_calendar/table_calendar.dart'; // 달력
import 'package:client/components/login_modal_screen.dart'; // 로그인 모달
import '../components/custom_app_bar.dart';
import '../config/api_config.dart';
import '../models/my_ranking_info.dart';
import '../models/ranking_api_response.dart';
import '../models/ranking_info.dart';


/// 선택한 날짜의 기록만 보여주는 페이지 (스크롤 가능, Container 사용)
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  _RankingScreenState createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with TickerProviderStateMixin {
  //탭 상태를 관리할 컨트롤러
  late TabController _tabController;

  //토큰 Flutter Secure Storage
  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 달력 상태
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  //기록을 위한 변수
  List<dynamic> _myRecords = []; // 전체 기록
  dynamic _selectedRecord; // 나의 기록 중에서 선택된 기록

  bool _isLoading = true; // 로딩 상태
  String? _error; // 에러 메시지

  RankingApiResponse? _rankingData;
  final List<String> _categoryOrder = [
    '1-3km', '3-5km', '5-10km', '10-21km', '21km~'
  ];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    initializeDateFormatting('ko_KR', null).then((_) { // 달력을 한글 날짜 포맷 데이터 초기화 후 로드
      _selectedDay = _focusedDay;
      _selectedRecord = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkLoginAndFetch();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 로그인 및 기록 조회
  Future<void> _checkLoginAndFetch() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      // 로그인 모달 표시
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => LoginModalScreen(),
      );

      // 모달 닫힌 뒤에도 여전히 비로그인 상태라면 이전 화면으로 돌아감
      final newToken = await _storage.read(key: _tokenKey);

      if (newToken == null) {
        context.pop();
      } else {
        setState(() {}); // 로그인 후 화면 갱신
      }
    }
    else{
      await _loadAllData(token);
    }
  }

  Future<void> _loadAllData(String token) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _fetchMyRecords(token),
        _fetchRankings(token),
      ]);
      setState(() {
        _myRecords = results[0] as List<dynamic>;
        _rankingData = results[1] as RankingApiResponse;
        _isLoading = false;
      });
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('403')) {
        if (mounted) {
          final newToken = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            builder: (_) => LoginModalScreen(),
          );

          if (newToken != null) {
            // 새 토큰을 받았다면 데이터 로딩을 다시 시도합니다.
            await _loadAllData(newToken);
          } else {
            // 로그인하지 않았다면 화면을 닫습니다.
            if (mounted) context.pop();
          }
        }
      } else {
        // 그 외 다른 에러 처리
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

    Future<List<dynamic>> _fetchMyRecords(String token) async {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getRunning()}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        return json.decode(utf8.decode(resp.bodyBytes)) as List<dynamic>;
      } else {
        throw Exception('나의 기록 로딩 실패: Status Code ${resp.statusCode}');
      }
    }

    Future<RankingApiResponse> _fetchRankings(String token) async {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getRanking()}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final _rankingData = json.decode(utf8.decode(response.bodyBytes));
        return RankingApiResponse.fromJson(_rankingData);
      } else {
        throw Exception('랭킹 정보 로딩 실패: Status Code ${response.statusCode}');
      }
    }

  String _formatDate(String? iso) {
    if(iso == null || iso.isEmpty){
      return "";
    }
    else{
      final utcDateTime = DateTime.parse(iso);
      final localDateTime = utcDateTime.toLocal();
      final formatter = DateFormat('a h시 m분', 'ko_KR');
      return formatter.format(localDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {

    // 로딩 및 에러 처리는 전체 화면에 공통으로 적용
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))));

    // 수정된 부분: Scaffold 구조를 TabBar와 TabBarView를 사용하도록 변경합니다.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    // 수정된 부분: Scaffold와 AppBar를 제거하고 Column을 반환합니다.
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
        actions: [],
      ),
      body: Column(
        children: [
          // 1. TabBar를 화면 상단에 배치합니다.
          TabBar(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: '나의 기록'),
              Tab(text: '랭킹'),
            ],
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
          ),

          // 2. 남은 공간을 모두 차지하도록 Expanded로 TabBarView를 감쌉니다.
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildMyRecordsView(), // 첫 번째 탭: 나의 기록 화면
                _buildRankingView(),   // 두 번째 탭: 랭킹 화면
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMyRecordsView() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    //조회를 위한 날짜 받아오기
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);

    //받아온 날짜를 통해 조회
    final filtered = _myRecords.where((rec) {
      return (rec['createdAt'] as String).startsWith(dateKey);
    }).toList();

    // 수정: 기록을 createdAt 기준 내림차순 정렬하여 최신 기록을 앞으로 배치
    filtered.sort((a, b) {
      return (b['createdAt'] as String).compareTo(a['createdAt'] as String);
    });

    // 선택된 날짜의 모든 기록(정렬 후)
    final allRecords = filtered;
    _selectedRecord ??= allRecords.isNotEmpty ? allRecords.first : null;
    // 수정: 최신 기록 1개와 나머지 기록 분리
    final dynamic selectedRecord = _selectedRecord;
    //final otherRecords = filtered.length > 1 ? filtered.sublist(1) : <dynamic>[];

    return ListView(
      children: [
        if (selectedRecord != null)
          _buildRecordContainer(context, selectedRecord)
        else
          Container(
            height: screenHeight * 0.22,
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white),
            alignment: Alignment.center,
            child: Text('이날의 기록이 없습니다', style: TextStyle(fontSize: 18)),
          ),

        Divider(thickness: 5,),

        Center( // 달력
          child: SizedBox(
            width: screenWidth * 0.9,
            child: TableCalendar(
              locale: 'ko_KR',
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 12),  // 기본 14~16 정도면 칸 폭을 넘칠 수 있음
                weekendStyle: TextStyle(fontSize: 12),
              ),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                    color: Color(0xFF767676), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(
                    color: Color(0xFFFF002B), shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),
        ),

        Divider(thickness: 5,),

        if (allRecords.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Text(
              '다른 기록',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          // SingleChildScrollView + Row로 가로 스크롤 가능하게 감싸기
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: allRecords.map((rec) {
                final bool isSelected = rec == _selectedRecord;
                return Padding(
                  padding: const EdgeInsets.only(left:8, right: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: isSelected ? Color(0xFFFF002B) : Color(0xFFD9D9D9),
                      foregroundColor: isSelected ? Colors.white : Color(0xFF767676),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      // 최소 너비를 0으로 두어 내용에 맞춰 줄어들게
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),  // 모서리 반경 설정
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedRecord = rec;
                      });
                    },
                    child: Text(
                      // “오전/오후 시:분” 포맷
                        _formatDate(rec['createdAt'] as String),
                      // DateFormat('a h:mm', 'ko_KR').format(
                      //   DateTime.parse(rec['createdAt'] as String),
                      // ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildRankingView() {
    if (_rankingData == null) {
      return Center(child: Text('랭킹 데이터를 불러올 수 없습니다.'));
    }
    return _buildRankingContent(_rankingData!);
  }

  Widget _buildRankingContent(RankingApiResponse data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.myRankings.isNotEmpty) _buildMyRankingSection(data.myRankings, context),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('구간별 Top 3', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: _categoryOrder.length,
            itemBuilder: (context, index) {
              final category = _categoryOrder[index];
              final rankers = data.topRankingsByCategory[category] ?? [];
              return _buildCategoryCard(category, rankers, context);
            },
          ),
        ),
      ],
    );
  }
}

Widget _buildMyRankingSection(List<MyRankingInfo> myRankings, BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text('나의 랭킹', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      Container(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12),
          itemCount: myRankings.length,
          itemBuilder: (context, index) {
            final myRank = myRankings[index];
            return Card(
              elevation: 1,
              child: Container(
                width: 220,
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(myRank.distanceCategory, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${myRank.myRank} 위 / ${myRank.totalRankedCount} 명'),
                        Text('상위 ${myRank.percentile.toStringAsFixed(1)}%', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildCategoryCard(String category, List<RankingInfo> rankers, BuildContext context) {
  return Card(
    elevation: 2,
    margin: EdgeInsets.only(bottom: 16.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/ranking/$category'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$category Top 3', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            rankers.isEmpty
                ? Padding(padding: const EdgeInsets.all(16.0), child: Center(child: Text('랭킹 기록이 없습니다.', style: TextStyle(color: Colors.grey))))
                : Column(
              children: List.generate(
                rankers.length > 3 ? 3 : rankers.length,
                    (index) => _buildRankerRow(index + 1, rankers[index], context),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildRankerRow(int rank, RankingInfo ranker, BuildContext context) {
  final pace = _formatPace(ranker.totalDistance, ranker.totalSeconds);
  final medalIcons = ['🥇', '🥈', '🥉'];
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Text(medalIcons[rank - 1], style: TextStyle(fontSize: 22)),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            'Runner ID: ${ranker.runnerId}', // TODO: runnerNickname을 받도록 백엔드 쿼리/DTO 수정 필요
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          pace,
          style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

// 날짜 선택마다 바뀌는 달린 정보와 경로
Widget _buildRecordContainer(BuildContext context, dynamic runningRecord) {
  final screenHeight = MediaQuery.of(context).size.height;
  // km 단위 거리 계산
  final distanceKm = (runningRecord['totalDistance'] as num) / 1000;
  // 총 시간 Duration으로 계산
  final totalTime = Duration(seconds: runningRecord['totalSeconds'] as int);
  // HH:mm:ss 형식 문자열
  final durStr = [
    totalTime.inHours.toString().padLeft(2, '0'),
    (totalTime.inMinutes % 60).toString().padLeft(2, '0'),
    (totalTime.inSeconds % 60).toString().padLeft(2, '0')
  ].join(':');
  // 1km 당 페이스 초 계산 후 mm:ss 형식
  final paceSec = (totalTime.inSeconds / distanceKm).round();
  final paceStr = '${Duration(seconds: paceSec).inMinutes.toString().padLeft(2,'0')}:${(Duration(seconds: paceSec).inSeconds % 60).toString().padLeft(2,'0')}';
  // 칼로리 (km * 60)
  final calorie = (distanceKm * 60).toStringAsFixed(2);

  return Container(
    height: screenHeight * 0.22, // 항목 높이 고정
    //margin: const EdgeInsets.symmetric(vertical: 16),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
    ),
    child: Column(
      children: [
        Column(
          children: [
            Column(
              children: [
                // 달린 거리+ 경로보기 시작
                Container(
                  height: screenHeight * 0.11,
                  child:
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,  // 추가: 텍스트 베이스라인 정렬
                    textBaseline: TextBaseline.alphabetic,            // 필수: 어떤 베이스라인을 쓸지 지정
                    children: [
                      Text(
                        '${distanceKm.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),  // 숫자와 단위 사이 여백
                      const Text(
                        'km',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          elevation: 0,
                          foregroundColor: Color(0xFFD9D9D9),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          context.push('/route' , extra: runningRecord);
                        },
                        child: const Text(
                          '경로보기',
                        ),
                      ),
                    ],
                  ),
                ) // 달린 거리+ 경로보기 종료
              ],
            ),
            Container(
              height: screenHeight * 0.03,
            ),
            //페이스, 시간, 칼로리 시작
            Container(
              height: screenHeight * 0.07,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                children: [
                  // 1) 페이스
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          paceStr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          '페이스',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // 세로 구분선
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                  ),

                  // 2) 시간
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          durStr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          '시간',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // 세로 구분선
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                  ),

                  // 3) 칼로리
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          calorie,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          '칼로리',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            //페이스, 시간, 칼로리 종료
          ],
        )
      ],
    ),
  );
}

String _formatPace(double totalDistance, int totalSeconds) {
  if (totalDistance < 1) return "-'--\"";
  double paceInSecondsPerKm = totalSeconds / (totalDistance / 1000);
  int minutes = paceInSecondsPerKm ~/ 60;
  int seconds = (paceInSecondsPerKm % 60).round();
  return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
}