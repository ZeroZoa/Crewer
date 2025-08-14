import 'dart:developer' as developer;

import 'package:flutter/material.dart'; // Flutter UI
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅
import 'package:intl/date_symbol_data_local.dart'; // 지역화된 날짜 포맷 초기화
import 'package:http/http.dart' as http; // HTTP 요청
import 'dart:convert'; // JSON 파싱
import 'package:go_router/go_router.dart'; // 라우팅
//import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart'; // 달력
import 'package:client/components/login_modal_screen.dart'; // 로그인 모달
import '../config/api_config.dart';
//import '../providers/auth_provider.dart';

/// 선택한 날짜의 기록만 보여주는 페이지 (스크롤 가능, Container 사용)
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  _RankingScreenState createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with TickerProviderStateMixin {
  //기록을 위한 변수
  List<dynamic> _records = []; // 전체 기록
  bool _loading = true; // 로딩 상태
  String? _error; // 에러 메시지

  // //랭킹을 위한 변수
  // List<dynamic> _allRankings = []; // 서버에서 받아온 전체 랭킹 리스트
  // Map<String, List<dynamic>> _rankingsByCategory = {};
  // String _selectedCategory = '1-3km'; // 현재 선택된 거리 구간
  // String? _myNickname; // 내 닉네임 (AuthProvider 등에서 가져와야 함)
  // int? _myRank; // 선택된 구간에서의 내 순위
  // double? _myPercentile; // 선택된 구간에서의 내 백분율

  // 달력 상태
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  dynamic _selectedRecord; // 나의 기록 중에서 선택된 기록

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  //탭 상태를 관리할 컨트롤러
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    initializeDateFormatting('ko_KR', null).then((_) { // 달력을 한글 날짜 포맷 데이터 초기화 후 로드
      _selectedDay = _focusedDay;
      _selectedRecord = null;
      setState(() {});
      _checkLoginAndFetch();
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
      await _fetchRecords(token);
    }
  }



  // 달린 기록을 받아오는 함수
  Future<void> _fetchRecords(String token) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getRunning()}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        _records = json.decode(resp.body) as List<dynamic>;
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        final newToken = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          builder: (_) => LoginModalScreen(),
        );

        if (newToken == null) {
          context.pop();
          return;
        }

        return _fetchRecords(newToken);
      } else {
        _error = '레코드를 불러올 수 없습니다.';
      }
    } catch (e) {
      _error = '오류가 발생했습니다.';
      developer.log(
        '오류 발생: $e',
        name: 'YourWidgetOrClassName',
        error: e,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }

  }

  @override
  Widget build(BuildContext context) {

    // 로딩 및 에러 처리는 전체 화면에 공통으로 적용
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))));

    // 수정된 부분: Scaffold 구조를 TabBar와 TabBarView를 사용하도록 변경합니다.
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    // 수정된 부분: Scaffold와 AppBar를 제거하고 Column을 반환합니다.
    return Column(
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
    );
  }


  Widget _buildMyRecordsView() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    //조회를 위한 날짜 받아오기
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);

    //받아온 날짜를 통해 조회
    final filtered = _records.where((rec) {
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
            width: screenWidth * 0.95,
            child: TableCalendar(
              locale: 'ko_KR',
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 12.5),  // 기본 14~16 정도면 칸 폭을 넘칠 수 있음
                weekendStyle: TextStyle(fontSize: 12.5),
              ),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                    color: Color(0xFF9CB4CD), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(
                    color: Colors.black, shape: BoxShape.circle),
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
                      backgroundColor: isSelected ? Colors.black : Color(0xFF9CB4CD),
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
                      DateFormat('a h:mm', 'ko_KR').format(
                        DateTime.parse(rec['createdAt'] as String),
                      ),
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
    return Center(
      child: Text(
        '랭킹 페이지입니다.',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
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
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          side: const BorderSide(                   // 수정: 테두리 색상 및 두께 지정
                            color: Colors.black,                    // 테두리 색상
                            width: 1,                                // 테두리 두께
                          ),
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

// @override
// Widget build(BuildContext context) {
//   if (_loading) {
//     return const Scaffold(
//       body: Center(child: CircularProgressIndicator()),
//     );
//   }
//   if (_error != null) {
//     return Scaffold(
//       body: Center(
//         child: Text(_error!, style: const TextStyle(color: Colors.red)),
//       ),
//     );
//   }
//
//   //조회를 위한 날짜 받아오기
//   final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);
//
//   //받아온 날짜를 통해 조회
//   final filtered = _records.where((rec) {
//     return (rec['createdAt'] as String).startsWith(dateKey);
//   }).toList();
//
//   // 수정: 기록을 createdAt 기준 내림차순 정렬하여 최신 기록을 앞으로 배치
//   filtered.sort((a, b) {
//     return (b['createdAt'] as String).compareTo(a['createdAt'] as String);
//   });
//
//   // 선택된 날짜의 모든 기록(정렬 후)
//   final allRecords = filtered;
//   _selectedRecord ??= allRecords.isNotEmpty ? allRecords.first : null;
//   // 수정: 최신 기록 1개와 나머지 기록 분리
//   final dynamic selectedRecord = _selectedRecord;
//   //final otherRecords = filtered.length > 1 ? filtered.sublist(1) : <dynamic>[];
//
//   return Scaffold(
//     body: SafeArea(
//       child: ListView(
//         children: [
//           if (selectedRecord != null)
//             _buildRecordContainer(context, selectedRecord)
//           else
//             Container(
//               height: 240,
//               margin: const EdgeInsets.symmetric(vertical: 4),
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               decoration: BoxDecoration(color: Colors.white),
//               alignment: Alignment.center,
//               child: Text('이날의 기록이 없습니다', style: TextStyle(fontSize: 18)),
//             ),
//
//           Divider(thickness: 5,),
//
//           // 달력
//           Center(
//             child: SizedBox(
//               width: 375,
//               child: TableCalendar(
//                 locale: 'ko_KR',
//                 firstDay: DateTime.utc(2024, 1, 1),
//                 lastDay: DateTime.utc(2030, 12, 31),
//                 focusedDay: _focusedDay,
//                 selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
//                 daysOfWeekStyle: DaysOfWeekStyle(
//                   weekdayStyle: TextStyle(fontSize: 12.5),  // 기본 14~16 정도면 칸 폭을 넘칠 수 있음
//                   weekendStyle: TextStyle(fontSize: 12.5),
//                 ),
//                 onDaySelected: (selected, focused) {
//                   setState(() {
//                     _selectedDay = selected;
//                     _focusedDay = focused;
//                   });
//                 },
//                 calendarStyle: const CalendarStyle(
//                   todayDecoration: BoxDecoration(
//                       color: Color(0xFF9CB4CD), shape: BoxShape.circle),
//                   selectedDecoration: BoxDecoration(
//                       color: Colors.black, shape: BoxShape.circle),
//                 ),
//                 headerStyle: const HeaderStyle(
//                   formatButtonVisible: false,
//                   titleCentered: true,
//                 ),
//               ),
//             ),
//           ),
//
//           Divider(thickness: 5,),
//
//           if (allRecords.isNotEmpty) ...[
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
//               child: Text(
//                 '다른 기록',
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//               ),
//             ),
//             // SingleChildScrollView + Row로 가로 스크롤 가능하게 감싸기
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: allRecords.map((rec) {
//                   final bool isSelected = rec == _selectedRecord;
//                   return Padding(
//                     padding: const EdgeInsets.only(left:8, right: 8),
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: isSelected ? Colors.black : Color(0xFF9CB4CD),
//                         foregroundColor: isSelected ? Colors.white : Colors.white,
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                         // 최소 너비를 0으로 두어 내용에 맞춰 줄어들게
//                         minimumSize: const Size(0, 32),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),  // 모서리 반경 설정
//                         ),
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _selectedRecord = rec;
//                         });
//                       },
//                       child: Text(
//                         // “오전/오후 시:분” 포맷
//                         DateFormat('a h:mm', 'ko_KR').format(
//                           DateTime.parse(rec['createdAt'] as String),
//                         ),
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ]
//         ],
//       ),
//     ),
//   );
// }