import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../components/custom_app_bar.dart';
import '../components/login_modal_screen.dart';
import '../components/profile/profile_avatar_picker.dart';
import '../components/profile/interest_chips.dart';
import '../components/profile/temperature_bar.dart';
import '../components/profile/follow_stats_row.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../models/member.dart';

/// 마이 프로필 화면
/// • 로그인 상태가 아닌 경우 자동으로 로그인 모달을 띄워 접근을 제한합니다.
class MyProfileScreen extends StatefulWidget {
  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> with WidgetsBindingObserver {
  Future<Member>? _profileFuture;
  Set<String> selectedInterests = {};
  String? _activityRegionName;
  bool _isLoading = true;
  String? _error;

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndLoad();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 앱이 다시 포커스를 받을 때 프로필 새로고침
    if (state == AppLifecycleState.resumed) {
      _refreshProfile();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 프로필 새로고침 (토큰이 있을 때만)
  Future<void> _refreshProfile() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null && mounted) {
      await _loadProfile(token);
    }
  }

  /// 로그인 확인 및 프로필 데이터 로드
  Future<void> _checkLoginAndLoad() async {
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
      await _loadProfile(token);
    }
  }

  Future<void> _loadProfile(String token) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _fetchProfile(token);
      setState(() {
        _profileFuture = Future.value(profile);
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
            await _loadProfile(newToken);
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

  Future<Member> _fetchProfile(String token) async {
    final profileResponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfileMe()}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (profileResponse.statusCode == 200) {
      final profile = Member.fromJson(json.decode(profileResponse.body));
      
      // 프로필 정보에서 이미 저장된 관심사 리스트를 Set으로 변환
      selectedInterests = {...(profile.interests ?? [])};
      
      // 마이프로필의 활동지역 정보 가져오기
      await _fetchMyActivityRegion(profile.username, token);
      
      return profile;
    } else {
      throw Exception('프로필 정보 로딩 실패: Status Code ${profileResponse.statusCode}');
    }
  }

  /// 마이프로필의 활동지역 정보를 가져오기
  Future<void> _fetchMyActivityRegion(String username, String token) async {
    try {
      final activityRegionResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/regions/members/activity-region'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (activityRegionResponse.statusCode == 200) {
        final responseData = json.decode(utf8.decode(activityRegionResponse.bodyBytes));
        
        // API 응답 형식에 따라 처리
        if (responseData is Map) {
          // 형식 1: { "success": true, "data": { "regionName": "..." } }
          if (responseData['success'] == true && responseData['data'] != null) {
            final activityRegion = responseData['data'];
            if (activityRegion['regionName'] != null) {
              setState(() {
                _activityRegionName = activityRegion['regionName'];
              });
            }
          }
          // 형식 2: { "regionName": "..." }
          else if (responseData['regionName'] != null) {
            setState(() {
              _activityRegionName = responseData['regionName'];
            });
          }
        }
      }
      // 404나 다른 에러는 무시 (활동 지역이 없는 경우)
    } catch (e) {
      // 활동지역 정보 조회 실패 시 무시 (활동 지역 없이 표시)
    }
  }

  /// 관심사 선택 모달 표시
  Future<void> _showInterestSelectorModal() async {
    Set<String> tempSelected = Set.from(selectedInterests);
    bool isLoadingCategories = true;
    Map<String, List<String>> categories = {};
    
    // 서버에서 관심사 카테고리 로드
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getInterestCategories()}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        categories = data.map((key, value) => MapEntry(key, List<String>.from(value)));
        isLoadingCategories = false;
      } else {
        // 실패 시 기본 카테고리 사용
        categories = _getDefaultInterestCategories();
        isLoadingCategories = false;
      }
    } catch (e) {
      // 에러 시 기본 카테고리 사용
      categories = _getDefaultInterestCategories();
      isLoadingCategories = false;
    }
    
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // 핸들 바
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // 제목
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "관심사 선택",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Color(0xFF757575)),
                          ),
                        ],
                      ),
                    ),
                    
                    // 관심사 선택 영역
                    Expanded(
                      child: isLoadingCategories
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: categories.entries.map((category) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 카테고리 제목
                                      Padding(
                                        padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                                        child: Text(
                                          category.key,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFF002B),
                                          ),
                                        ),
                                      ),
                                      
                                      // 카테고리 내 관심사들
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: category.value.map((interest) {
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
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: isSelected ? const Color(0xFFFF002B) : Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Color(0xFFFF002B),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                interest,
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : Color(0xFFFF002B),
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                    
                    // 저장 버튼
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            
                            // 서버에 저장
                            try {
                              await _saveInterestsToServer(tempSelected.toList());
                              setState(() {
                                selectedInterests = tempSelected.toSet();
                              });
                              // 프로필 새로고침
                              final token = await _storage.read(key: _tokenKey);
                              if (token != null) {
                                await _loadProfile(token);
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('관심사가 저장되었습니다')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('관심사 저장 실패: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF002B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "저장",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 서버에 관심사 저장
  Future<void> _saveInterestsToServer(List<String> interests) async {
    final token = await _storage.read(key: 'token');

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

  /// 기본 관심사 카테고리 (서버 연결 실패 시 폴백)
  Map<String, List<String>> _getDefaultInterestCategories() {
    return {
      '러닝 스타일 🏃': [
        '가벼운 조깅',
        '정기적인 훈련',
        '대회 준비',
        '트레일 러닝',
        '플로깅',
        '새벽/아침 러닝',
        '저녁/야간 러닝',
      ],
      '함께하고 싶은 운동 🤸‍♀️': [
        '등산',
        '자전거',
        '헬스/웨이트',
        '요가/스트레칭',
        '클라이밍',
      ],
      '소셜/라이프스타일 🍻': [
        '맛집 탐방',
        '카페/수다',
        '함께 성장',
        '기록 공유',
        '사진/영상 촬영',
        '조용한 소통',
        '반려동물과 함께',
      ],
    };
  }

  /// 로그아웃 처리: 토큰 삭제 후 홈으로 이동
  Future<void> _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        appBarType: AppBarType.backOnly,
        title: const Text(
          '마이페이지',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        onSearchPressed: () {
        },
      ),
      body: _profileFuture == null 
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Member>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFFF002B),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '오류가 발생했습니다',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final token = await _storage.read(key: _tokenKey);
                      if (token != null) {
                        await _loadProfile(token);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9CB4CD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final member = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 헤더
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        // 프로필 이미지
                        ProfileAvatarPicker(
                          avatarUrl: member.avatarUrl,
                          radius: 40,
                          onUploadSuccess: () async {
                            final token = await _storage.read(key: _tokenKey);
                            if (token != null) {
                              await _loadProfile(token);
                            }
                          },
                          onUploadError: (error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        
                        // 닉네임 및 팔로우 통계
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.nickname ?? member.username,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FollowStatsRow(
                                username: member.username,
                                followersCount: member.followersCount,
                                followingCount: member.followingCount,
                                isMyProfile: true,
                                showActivityRegion: _activityRegionName != null,
                                activityRegionName: _activityRegionName,
                                onReturn: () {
                                  // 팔로우 리스트에서 돌아왔을 때 프로필 새로고침
                                  _refreshProfile();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 온도 바
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24.0),
                    child: TemperatureBar(
                      temperature: member.temperature ?? 36.5,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 관심사
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '관심사',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await _showInterestSelectorModal();
                              },
                              child: const Text(
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
                        const SizedBox(height: 12),
                        InterestChips(
                          interests: member.interests,
                          emptyMessage: '등록된 관심사가 없습니다.',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 활동 내역
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      children: [
                        _buildActivityItem(
                          icon: Icons.article_outlined,
                          title: '내가 쓴 피드',
                          onTap: () {
                            context.push('/me/feeds');
                          },
                        ),
                        Divider(height: 1, color: Color(0xFFDBDBDB)),
                        _buildActivityItem(
                          icon: Icons.favorite_outline,
                          title: '내가 좋아요한 피드',
                          onTap: () {
                            context.push('/me/liked-feeds');
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 로그아웃
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _logout,
                        child: const Text(
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
            return const Center(child: Text('알 수 없는 오류'));
          }
        },
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: Color(0xFF767676),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Color(0xFF767676),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
