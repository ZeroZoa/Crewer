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

        final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final filtered = _myRecords.where((rec) => (rec['createdAt'] as String).startsWith(dateKey)).toList();
        filtered.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
        _selectedRecord = filtered.isNotEmpty ? filtered.first : null;
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


  @override
  Widget build(BuildContext context) {

    // 로딩 및 에러 처리는 전체 화면에 공통으로 적용
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))));

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
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
            labelColor: Color(0xFFFF002B),
            unselectedLabelColor: Color(0xFFBDBDBD),
            indicatorColor: Color(0xFFFF002B),
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

    filtered.sort((a, b) {
      return (b['createdAt'] as String).compareTo(a['createdAt'] as String);
    });

    // 선택된 날짜의 모든 기록(정렬 후)
    final allRecords = filtered;
    final dynamic selectedRecord = _selectedRecord;

    return ListView(
      children: [
        if (selectedRecord != null)
          _buildRecordContainer(context, selectedRecord)
        else
          Container(
            height: screenHeight * 0.245,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(color: Colors.white),
            alignment: Alignment.center,
            child: Text('이날의 기록이 없습니다', style: TextStyle(fontSize: 18)),
          ),

        Container(
          padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
          height: screenHeight * 0.5,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8), // 배경색 추가
          ),
          child: Column( // 달력
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: screenWidth * 1,
                height: screenHeight * 0.4172,
                // decoration을 사용하여 배경색과 테두리 둥글기를 설정합니다.
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF), // 배경색 추가
                  borderRadius: BorderRadius.circular(20.0), // 테두리 둥글기 추가
                ),
                child: TableCalendar(
                  rowHeight: 46,
                  locale: 'ko_KR',
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontSize: 12),
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
                      color: Color(0xFF767676),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Color(0xFFFF002B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              if (allRecords.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: allRecords.map((rec) {
                      final bool isSelected = rec == _selectedRecord;
                      return Padding(
                        padding: const EdgeInsets.only(left:8, right: 8, top: 8),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: isSelected ? Color(0xFFFF002B) : Color(0xFF767676),
                            foregroundColor: isSelected ? Colors.white : Colors.white,
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
                            _formatTime(rec['createdAt'] as String),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // 수정한 부분: 상하 패딩을 조금 조절
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              // 수정한 부분: 좌우에 각각 12의 여백을 추가합니다.
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    _formatDate(runningRecord['createdAt']),
                    style: const TextStyle(
                      color: Color(0xFF767676),
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      elevation: 0,
                      foregroundColor: const Color(0xFF767676),
                      backgroundColor: const Color(0xFFFF002B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      context.push('/route' , extra: runningRecord);
                    },
                    child: const Text(
                      '경로보기',
                      style: TextStyle(
                          color: Colors.white
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${distanceKm.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4), // km 단위와 숫자 사이 간격
                  const Text(
                    'km',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(child: _infoBox('평균 페이스', paceStr)),
                const SizedBox(width: 8),
                Expanded(child: _infoBox('달린 시간', durStr)),
                const SizedBox(width: 8),
                Expanded(child: _infoBox('칼로리', calorie)),
              ],
            ),
          ],
        )
    );
  }


  Widget _infoBox(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            ]
        ),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  //랭킹 정보를 불러와 정보의 유무 확인
  Widget _buildRankingView() {
    if (_rankingData == null) {
      return Center(child: Text('랭킹 데이터를 불러올 수 없습니다.'));
    }
    return _buildRankingContent(_rankingData!);
  }

  //랭킹 정보가 있다면 데이터를 나눠 사용자에게 보여줌(상위 몇%)
  Widget _buildRankingContent(RankingApiResponse data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.myRankings.isNotEmpty) _buildMyRankingSection(data.myRankings, context),
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

  //랭킹 정보가 있다면 데이터를 나눠 사용자에게 보여줌(상위 랭커 순위, 페이스)
  Widget _buildMyRankingSection(List<MyRankingInfo> myRankings, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('나의 랭킹', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            //margin: EdgeInsets.fromLTRB(16, 0, 16, 0),
            itemCount: myRankings.length,
            itemBuilder: (context, index) {
              final myRank = myRankings[index];
              return Container(
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
                width: 220,
                margin: EdgeInsets.fromLTRB(6, 2, 6, 12),
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
                        Text('상위 ${myRank.percentile.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
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
      color: Color(0xFFFBF6F6),
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          MyRankingInfo? myRankInfo;
          try {
            myRankInfo = _rankingData!.myRankings.firstWhere(
                  (r) => r.distanceCategory == category,
            );
          } catch (e) {
            myRankInfo = null; // 해당 카테고리에 내 기록이 없을 수 있음
          }
          context.push(
            '/ranking/$category',
            extra: {
              'myRankInfo': myRankInfo,
              'topRankings': rankers,
            },
          );
        },
        child: Container(
              padding: const EdgeInsets.only(left:16, top: 12, bottom: 8),
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
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("거리", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF767676))),
                      SizedBox(
                        width: 100,
                        child: Text(
                            '$category',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500
                            )
                        ),
                      ),
                      SizedBox(height:60),
                    ],
                  ),
                  SizedBox(
                    width: 50,
                  ),
                  Expanded(
                    child: rankers.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          '랭킹 기록이 없습니다.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                        : Column(
                      children: [
                        SizedBox(height: 20),
                        ...List.generate(
                          rankers.length > 3 ? 3 : rankers.length,
                              (index) => _buildRankerRow(index + 1, rankers[index], context),
                        ),
                        // SizedBox는 그대로 둡니다.
                      ],
                    ),
                  )
                ],
              ),
            ),
        ),
      );
  }

  Widget _buildRankerRow(int rank, RankingInfo ranker, BuildContext context) {
    final pace = _formatPace(ranker.totalDistance, ranker.totalSeconds);
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        children: [
          Text('$rank', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFFFF002B))),
          SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              ranker.runnerNickname,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF767676)),
            ),
          ),
          Text(
            pace,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
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

  String _formatTime(String? iso) {
    if(iso == null || iso.isEmpty){
      return "";
    }
    else{
      final utcDateTime = DateTime.parse(iso);
      final localDateTime = utcDateTime.toLocal();
      final formatter = DateFormat('HH:MM', 'ko_KR');
      return formatter.format(localDateTime);
    }
  }

  String _formatDate(String? iso) {
    if(iso == null || iso.isEmpty){
      return "";
    }else{
      final utcDateTime = DateTime.parse(iso);
      final localDateTime = utcDateTime.toLocal();
      final formatter = DateFormat('yyyy년 MM월 dd일', 'ko_KR');
      return formatter.format(localDateTime);
    }
  }
}

