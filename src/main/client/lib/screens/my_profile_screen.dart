import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart'; // 로그인 모달 화면
import 'package:provider/provider.dart';
import '../components/custom_app_bar.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../models/member.dart';

/// 마이 프로필 화면
/// • 로그인 상태가 아닌 경우 자동으로 로그인 모달을 띄워 접근을 제한합니다.
class MyProfileScreen extends StatefulWidget {
  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  late Future<Member> _profileFuture;
  late AnimationController _controller;
  late Animation<double> _animation;
  double _targetTemperature = 36.5; // 실제 프로필에서 받아온 값으로 대체
  Set<String> selectedInterests = Set<String>(); // 프로필 화면에서 선택된 관심사
  int _followersCount = 0;
  int _followingCount = 0;

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthentication());
    _profileFuture = fetchProfile();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _animation = Tween<double>(
      begin: 0,
      end: _targetTemperature,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    // 프로필 정보 받아온 후에 _controller.forward() 호출 필요!
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 인증 상태 확인
  Future<void> _checkAuthentication() async {
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
  }

  Future<Member> fetchProfile() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) throw Exception('로그인이 필요합니다');
    
    // 프로필 정보와 팔로우 통계를 동시에 가져오기
    final profileResponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfileMe()}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
          if (profileResponse.statusCode == 200) {
        final profile = Member.fromJson(json.decode(profileResponse.body));
      
      // 팔로우 통계 가져오기
      try {
        final followResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/follows/check/${profile.username}'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (followResponse.statusCode == 200) {
          final followData = json.decode(followResponse.body);
          setState(() {
            _followersCount = followData['followerCount'] ?? 0;
            _followingCount = followData['followingCount'] ?? 0;
          });
        }
      } catch (e) {
        print('팔로우 통계 로드 실패: $e');
      }
      
      // 프로필 정보 받아온 후에 _controller.forward() 호출 필요!
              _targetTemperature = profile.temperature ?? 36.5;
      _animation = Tween<double>(
        begin: 0,
        end: _targetTemperature,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward();
      // 프로필 정보에서 이미 저장된 관심사 리스트를 Set으로 변환
              selectedInterests = {...(profile.interests ?? [])};
      return profile;
    } else {
      throw Exception('프로필 정보를 불러오지 못했습니다');
    }
  }


  /// 로그아웃 처리: 토큰 삭제 후 홈으로 이동
  Future<void> _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        appBarType: AppBarType.settings,
        title: Text(
          '마이페이지',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        onSearchPressed: () {
          // TODO: 설정 화면으로 이동
        },
      ),
      body: FutureBuilder<Member>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('프로필 정보를 불러올 수 없습니다.'));
          } else if (snapshot.hasData) {
            final member = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: member.avatarUrl != null
                              ? NetworkImage(member.avatarUrl!)
                              : null,
                          child: member.avatarUrl == null
                              ? Icon(Icons.person, size: 40, color: Colors.grey[600])
                              : null,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.nickname ?? member.username,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                member.username,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      context.push('/me/followers');
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '팔로워 ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${_followersCount}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '·',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      context.push('/me/following');
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '팔로잉 ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${_followingCount}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(24.0),
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '온도 : ${_animation.value.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _animation.value / 100,
                                  backgroundColor: Colors.transparent,
                                  color: Color(0xFFFF002B),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '관심사',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await showInterestSelector(context, selectedInterests, (
                                  newList,
                                ) async {
                                  await saveInterestsToServer(
                                    newList,
                                  );
                                  setState(() {
                                    selectedInterests = newList.toSet();
                                    _profileFuture = fetchProfile();
                                  });
                                });
                              },
                              child: Text(
                                '수정하기',
                                style: TextStyle(
                                  color: Color(0xFFFF002B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        (member.interests?.isEmpty ?? true)
                            ? Container(
                                width: double.infinity,
                                child: Text(
                                  '등록된 관심사가 없습니다.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                            : Container(
                                width: double.infinity,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (member.interests ?? [])
                                      .map((interest) => Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Color(0xFFFF002B), width: 1),
                                              borderRadius: BorderRadius.circular(20),
                                              color: Colors.white,
                                            ),
                                            child: Text(
                                              interest,
                                              style: TextStyle(
                                                color: Color(0xFFFF002B),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      children: [
                        _buildActivityItem(
                          icon: Icons.article_outlined,
                          title: '내가 쓴 피드',
                          onTap: () {
                            context.push('/me/feeds');
                          },
                        ),
                        Divider(height: 1, color: Colors.grey[300]),
                        _buildActivityItem(
                          icon: Icons.favorite_outline,
                          title: '내가 좋아요한 피드',
                          onTap: () {
                            context.push('/me/liked-feeds');
                          },
                        ),
                        Divider(height: 1, color: Colors.grey[300]),
                        _buildActivityItem(
                          icon: Icons.chat_bubble_outline,
                          title: '내가 쓴 댓글',
                          onTap: () {
                            // TODO: 내가 쓴 댓글 화면으로 이동
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(24.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _logout,
                        child: Text(
                          '로그아웃',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFFF002B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: Text('알 수 없는 오류'));
          }
        },
      ),
    );
  }

  Widget _buildStatItem(String label, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[700],
              size: 24,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// 관심사 키워드 예시
const List<String> allInterests = [
  '러닝', '독서', '음악', '여행', '사진',
    '요리', '운동', '영화', '게임', '미술',
    '등산', '수영', '자전거', '테니스', '골프',
    '피아노', '기타', '춤', '요가', '필라테스',
    '명상', '캠핑', '낚시', '스키', '스노보드',
    '축구', '농구', '야구', '배구', '탁구'
];

// 관심사 선택 모달
Future<void> showInterestSelector(
  BuildContext context,
  Set<String> selected,
  Function(List<String>) onSave,
) async {
  // 팝업이 열릴 때 이미 저장된 관심사로 초기화
  Set<String> tempSelected = Set.from(selected);
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 핸들 바
                  Container(
                    margin: EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 제목
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "관심사 선택",
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // 관심사 선택 영역
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: allInterests.map((interest) {
                        final isSelected = tempSelected.contains(interest);
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                tempSelected.remove(interest);
                              } else {
                                tempSelected.add(interest);
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(0xFFFF002B) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected ? Color(0xFFFF002B) : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              interest,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 32),
                  // 저장 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          onSave(tempSelected.toList());
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF002B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "저장",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> saveInterestsToServer(List<String> interests) async {
  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final token = await _storage.read(key: _tokenKey);

  final response = await http.put(
    Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}/me/interests'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: json.encode(interests),
  );
  if (response.statusCode != 200) {
    throw Exception('관심사 저장 실패');
  }
}
