import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';
import '../config/api_config.dart';
import '../services/follow_service.dart';
import '../models/member.dart';
import '../components/custom_app_bar.dart';

/// 다른 사용자의 프로필 화면
/// • 로그인 상태가 아닌 경우 자동으로 로그인 모달을 띄워 접근을 제한합니다.
class UserProfileScreen extends StatefulWidget {
  final String username; // 조회할 사용자의 username

  const UserProfileScreen({Key? key, required this.username}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}



class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late Future<Member> _profileFuture;
  late AnimationController _controller;
  late Animation<double> _animation;
  double _targetTemperature = 36.5;
  bool _isCreatingChat = false;
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  String? _activityRegionName; // 활동지역 이름

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 포커스를 받을 때마다 팔로우 상태 확인
    _checkFollowStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 앱이 다시 포커스를 받을 때 팔로우 상태 확인
    if (state == AppLifecycleState.resumed) {
      _checkFollowStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  /// 팔로우 상태 확인
  Future<void> _checkFollowStatus() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return;

      final followResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/follows/check/${widget.username}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (followResponse.statusCode == 200) {
        final followData = json.decode(followResponse.body);
        
        // 서버 응답에서 다양한 필드명을 시도
        bool isFollowing = false;
        if (followData.containsKey('isFollowing')) {
          isFollowing = followData['isFollowing'] ?? false;
        } else if (followData.containsKey('following')) {
          isFollowing = followData['following'] ?? false;
        }
        
        setState(() {
          _isFollowing = isFollowing;
          _followersCount = followData['followerCount'] ?? 0;
          _followingCount = followData['followingCount'] ?? 0;
        });
      }
    } catch (e) {
      // 팔로우 상태 확인 실패 시 무시
    }
  }

  Future<Member> fetchProfile() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('로그인이 필요합니다');
    
    // 프로필 정보 가져오기
    final profileResponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfileByUsername(widget.username)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (profileResponse.statusCode == 200) {
      final profile = Member.fromJson(json.decode(profileResponse.body));
      
      _targetTemperature = profile.temperature ?? 36.5;
      _animation = Tween<double>(
        begin: 0,
        end: _targetTemperature,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward();
      
      // 사용자의 활동지역 정보 가져오기
      await _fetchUserActivityRegion(widget.username, token);
      
      return profile;
    } else {
      throw Exception('프로필 정보를 불러오지 못했습니다');
    }
  }

  /// 사용자의 활동지역 정보를 가져오기
  Future<void> _fetchUserActivityRegion(String username, String token) async {
    try {
      // 사용자의 활동지역 정보 가져오기
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

  /// 1대1 채팅방 생성 (임시 구현)
  Future<void> _createDirectChat() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('로그인이 필요합니다');
    if (_isCreatingChat) return;
    
    setState(() => _isCreatingChat = true);
    
    try {
      // TODO: 실제 채팅방 생성 API 구현
      
      await Future.delayed(Duration(seconds: 1)); // 임시 딜레이
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getJoinDirectChat(widget.username)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print(resp.statusCode);
      final data = json.decode(resp.body);
      print(data['id']);
      print(data['name']);
      print(data['currentParticipants']);
      print(data['memberId1']);
      context.push('/chat/${data['id']}');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('1대1 채팅 기능은 준비 중입니다')),
      // );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방 생성 중 오류가 발생했습니다')),
        
      );
    } finally {
      setState(() => _isCreatingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 배경색을 연한 회색으로 설정
      appBar: CustomAppBar(
        appBarType: AppBarType.backWithMore,
        title: Text(''), // 텍스트 비워두기
        onNotificationPressed: () {
          // TODO: 더보기 기능 구현
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
                  // 정보 보드 (프로필 정보) - 하얀색 배경
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: member.avatarUrl != null
                              ? NetworkImage('${ApiConfig.baseUrl}${member.avatarUrl!}')
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
                                  fontSize: 14, // 이메일 텍스트 더 작게
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      context.push('/user/${member.username}/followers');
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '팔로워 ',
                                            style: TextStyle(
                                              fontSize: 16, // 팔로워 텍스트 키우기
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${_followersCount}',
                                            style: TextStyle(
                                              fontSize: 18, // 숫자를 더 크게
                                              fontWeight: FontWeight.bold, // 숫자를 진한 볼드로
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
                                      context.push('/user/${member.username}/following');
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '팔로잉 ',
                                            style: TextStyle(
                                              fontSize: 16, // 팔로잉 텍스트 키우기
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${_followingCount}',
                                            style: TextStyle(
                                              fontSize: 18, // 숫자를 더 크게
                                              fontWeight: FontWeight.bold, // 숫자를 진한 볼드로
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
                  
                  SizedBox(height: 8), // 파티션 간 간격
                  
                  // 팔로우/언팔로우 및 1:1 채팅 버튼 보드 - 하얀색 배경
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleFollowToggle(member.username),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing ? Colors.grey[300] : Color(0xFFFF002B),
                              foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _isFollowing ? "언팔로우" : "팔로우",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isCreatingChat ? null : _createDirectChat,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF002B),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isCreatingChat
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    "1:1 채팅",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8), // 파티션 간 간격
                  
                  // 온도 바 보드 - 하얀색 배경
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
                  
                  SizedBox(height: 8), // 파티션 간 간격
                  
                  // 관심사 보드 - 하얀색 배경
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '관심사',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
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
                  
                  SizedBox(height: 8), // 파티션 간 간격
                  
                  // 피드 리스트 보드 - 하얀색 배경
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      children: [
                        _buildActivityItem(
                          icon: Icons.article_outlined,
                          title: '${member.nickname ?? member.username}님이 쓴 피드',
                          onTap: () {
                            context.push('/user/${member.username}/feeds');
                          },
                        ),
                      ],
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
        double progress = _animation.value / 100;
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

  Widget _buildFollowButton(String username) {
    return ElevatedButton(
      onPressed: () => _handleFollowToggle(username),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFollowing ? Colors.grey[300] : Color(0xFF9CB4CD),
        foregroundColor: _isFollowing ? Colors.black : Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Text(
        _isFollowing ? "언팔로우" : "팔로우",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _handleFollowToggle(String username) async {
    try {
      if (_isFollowing) {
        // 언팔로우
        await FollowService.unfollowUser(username);
        setState(() {
          _isFollowing = false;
          _followersCount = (_followersCount - 1).clamp(0, double.infinity).toInt();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('언팔로우 되었습니다')),
        );
      } else {
        // 팔로우
        await FollowService.followUser(username);
        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('팔로우 되었습니다')),
        );
      }
      
      await _checkFollowStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 4), // 패딩 조정
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