import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart'; // 로그인 모달 화면
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _activityRegionName; // 활동지역 이름

  // 프로필 이미지 관련 변수들
  File? _selectedImage;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

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
      
      // 마이프로필의 활동지역 정보 가져오기
      await _fetchMyActivityRegion(profile.username, token);
      
      return profile;
    } else {
      throw Exception('프로필 정보를 불러오지 못했습니다');
    }
  }

  /// 마이프로필의 활동지역 정보를 가져오기
  Future<void> _fetchMyActivityRegion(String username, String token) async {
    try {
      // 마이프로필의 활동지역 정보 가져오기
      final activityRegionResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/regions/members/activity-region'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (activityRegionResponse.statusCode == 200) {
        final responseData = json.decode(activityRegionResponse.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final activityRegion = responseData['data'];
          setState(() {
            _activityRegionName = activityRegion['regionName'];
          });
        }
      }
    } catch (e) {
      // 활동지역 정보 조회 실패 시 무시
    }
  }

  /// 이미지 선택 메서드
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        
        // 이미지 업로드
        await _uploadProfileImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
      );
    }
  }

  /// 프로필 이미지 업로드 메서드
  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다')),
        );
        return;
      }

      // MultipartFile 생성
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/profile/me/avatar'),
      );

      // 헤더 설정
      request.headers['Authorization'] = 'Bearer $token';

      // 파일 추가
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        ),
      );

      // 요청 전송
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 이미지가 업로드되었습니다')),
        );
        
        // 프로필 정보 새로고침
        setState(() {
          _profileFuture = fetchProfile();
        });
      } else {
        final responseBody = await response.stream.bytesToString();
        print('프로필 이미지 업로드 실패: ${response.statusCode} - $responseBody');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 이미지 업로드에 실패했습니다')),
        );
      }
    } catch (e) {
      print('프로필 이미지 업로드 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 이미지 업로드 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
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
                        GestureDetector(
                          onTap: _isUploadingImage ? null : _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: member.avatarUrl != null
                                    ? NetworkImage(member.avatarUrl!.startsWith('http') 
                                        ? member.avatarUrl! 
                                        : '${ApiConfig.baseUrl}${member.avatarUrl!}')
                                    : null,
                                child: member.avatarUrl == null
                                    ? Icon(Icons.person, size: 40, color: Colors.grey[600])
                                    : null,
                              ),
                              // 편집 아이콘 (업로드 중일 때는 로딩 표시)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _isUploadingImage ? Colors.grey : Color(0xFFFF002B),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: _isUploadingImage
                                      ? SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Icon(
                                          Icons.camera_alt,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ],
                          ),
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
                                  if (_activityRegionName != null) ...[
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
                                    Text(
                                      _activityRegionName!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
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

// 관심사 카테고리별 목록 (서버에서 가져올 예정)
Map<String, List<String>> interestCategories = {
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

// 관심사 선택 모달
Future<void> showInterestSelector(
  BuildContext context,
  Set<String> selected,
  Function(List<String>) onSave,
) async {
  // 팝업이 열릴 때 이미 저장된 관심사로 초기화
  Set<String> tempSelected = Set.from(selected);
  bool isLoadingCategories = true;
  Map<String, List<String>> categories = {};
  
  // 서버에서 관심사 카테고리 로드
  Future<void> loadCategories() async {
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
        categories = interestCategories;
        isLoadingCategories = false;
      }
    } catch (e) {
      // 에러 시 기본 카테고리 사용
      categories = interestCategories;
      isLoadingCategories = false;
    }
  }
  
  await loadCategories();
  
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
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
                  Expanded(
                    child: isLoadingCategories
                        ? Center(child: CircularProgressIndicator())
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
                                        style: TextStyle(
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
