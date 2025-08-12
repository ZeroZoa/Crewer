import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart'; // 로그인 모달 화면
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

/// 마이 프로필 화면
/// • 로그인 상태가 아닌 경우 자동으로 로그인 모달을 띄워 접근을 제한합니다.
class MyProfileScreen extends StatefulWidget {
  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class Profile {
  final String username;
  final String nickname;
  final String avatarUrl;
  final double temperature;
  final List<String> interests;

  Profile({
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.temperature,
    required this.interests,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      username: json['username'],
      nickname: json['nickname'],
      avatarUrl: json['avatarUrl'],
      temperature: (json['temperature'] as num).toDouble(),
      interests: List<String>.from(json['interests'] ?? []),
    );
  }
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  late Future<Profile> _profileFuture;
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

  Future<Profile> fetchProfile() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) throw Exception('로그인이 필요합니다');
    
    // 프로필 정보와 팔로우 통계를 동시에 가져오기
    final profileResponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfileMe()}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (profileResponse.statusCode == 200) {
      final profile = Profile.fromJson(json.decode(profileResponse.body));
      
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
      _targetTemperature = profile.temperature;
      _animation = Tween<double>(
        begin: 0,
        end: _targetTemperature,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward();
      // 프로필 정보에서 이미 저장된 관심사 리스트를 Set으로 변환
      selectedInterests = {...profile.interests};
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
      body: FutureBuilder<Profile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('프로필 정보를 불러올 수 없습니다.'));
          } else if (snapshot.hasData) {
            final profile = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(profile.avatarUrl),
                      ),
                      SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.nickname,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            profile.username,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // 팔로워/팔로잉 통계
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('팔로워', _followersCount, () {
                        context.push('/me/followers');
                      }),
                      _buildStatItem('팔로잉', _followingCount, () {
                        context.push('/me/following');
                      }),
                    ],
                  ),
                  SizedBox(height: 16),
                  buildTemperatureBar(),
                  SizedBox(height: 16),
                  Text(
                    '관심사',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  profile.interests.isEmpty
                      ? Text(
                        '등록된 관심사가 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      )
                      : Wrap(
                        spacing: 8,
                        children:
                            profile.interests
                                .map((interest) => Chip(label: Text(interest)))
                                .toList(),
                      ),
                  SizedBox(height: 24),
                  Divider(height: 1, color: Colors.grey[300]),
                  ListTile(
                    leading: Icon(
                      Icons.article_outlined,
                      color: Colors.grey[700],
                    ),
                    title: Text('내가 쓴 피드'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/me/feeds');
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  ListTile(
                    leading: Icon(
                      Icons.favorite_border,
                      color: Colors.grey[700],
                    ),
                    title: Text('내가 좋아요한 피드'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/me/liked-feeds');
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  Spacer(),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await showInterestSelector(context, selectedInterests, (
                          newList,
                        ) async {
                          await saveInterestsToServer(
                            newList,
                          ); // PUT /profile/me/interests
                          // 저장 후 프로필 정보 새로고침
                          setState(() {
                            selectedInterests = newList.toSet();
                            _profileFuture =
                                fetchProfile(); // FutureBuilder용 프로필 정보 새로고침
                          });
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF9CB4CD),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text("관심사 선택"),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF9CB4CD),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        '로그아웃',
                        style: TextStyle(fontSize: 16, color: Colors.white),
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

  Widget buildTemperatureBar() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double progress = _animation.value / 100; // 0~1로 변환
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('온도: ${_animation.value.toStringAsFixed(1)}°C'),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 16,
              backgroundColor: Colors.grey[300],
              color: Color(0xFF9CB4CD),
            ),
          ],
        );
      },
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
}

// 관심사 키워드 예시
const List<String> allInterests = [
  "러닝",
  "음악",
  "여행",
  "독서",
  "영화",
  "요리",
  "헬스",
  "게임",
  "사진",
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
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "관심사 선택",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      allInterests.map((interest) {
                        final isSelected = tempSelected.contains(
                          interest,
                        ); // 이미 저장된 관심사면 true!
                        return ChoiceChip(
                          label: Text(interest),
                          selected: isSelected,
                          selectedColor: Color(0xFF9CB4CD), // 밝은 색
                          backgroundColor: Colors.grey[300], // 비활성화 색
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                tempSelected.add(interest);
                              } else {
                                tempSelected.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    onSave(tempSelected.toList());
                    Navigator.pop(context);
                  },
                  child: Text("저장"),
                ),
              ],
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
