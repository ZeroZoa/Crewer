import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';
import '../config/api_config.dart';
import '../services/follow_service.dart';
import '../models/member.dart';

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
      return profile;
    } else {
      throw Exception('프로필 정보를 불러오지 못했습니다');
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
      body: FutureBuilder<Member>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('프로필 정보를 불러올 수 없습니다.'));
                     } else if (snapshot.hasData) {
             final member = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                                             CircleAvatar(
                         radius: 40,
                         backgroundImage: member.avatarUrl != null
                             ? NetworkImage(member.avatarUrl!)
                             : null,
                       ),
                      SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                                                     Text(
                             member.nickname ?? member.username,
                             style: TextStyle(
                               fontSize: 24,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                          SizedBox(height: 8),
                                                     Text(
                             member.username,
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
                         context.push('/user/${member.username}/followers');
                       }),
                       _buildStatItem('팔로잉', _followingCount, () {
                         context.push('/user/${member.username}/following');
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
                                     (member.interests?.isEmpty ?? true)
                       ? Text(
                         '등록된 관심사가 없습니다.',
                         style: TextStyle(color: Colors.grey),
                       )
                       : Wrap(
                         spacing: 8,
                         children:
                             (member.interests ?? [])
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
                                         title: Text('${member.nickname ?? member.username}님이 쓴 피드'),
                    trailing: Icon(Icons.chevron_right),
                                         onTap: () {
                       // 해당 사용자의 피드 목록 화면으로 이동
                       context.push('/user/${member.username}/feeds');
                     },
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  Spacer(),
                  // 팔로우/언팔로우 버튼과 채팅 버튼을 나란히 배치
                  Row(
                    children: [
                                             Expanded(
                         child: _buildFollowButton(member.username),
                       ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isCreatingChat ? null : _createDirectChat,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF9CB4CD),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          icon: _isCreatingChat
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.chat_bubble_outline, size: 24),
                          label: _isCreatingChat
                              ? Text(
                                  "채팅 중...",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "채팅",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
} 