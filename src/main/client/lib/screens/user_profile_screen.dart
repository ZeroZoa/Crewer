import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';
import '../config/api_config.dart';

/// 다른 사용자의 프로필 화면
/// • 로그인 상태가 아닌 경우 자동으로 로그인 모달을 띄워 접근을 제한합니다.
class UserProfileScreen extends StatefulWidget {
  final String username; // 조회할 사용자의 username

  const UserProfileScreen({Key? key, required this.username}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
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

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late Future<Profile> _profileFuture;
  late AnimationController _controller;
  late Animation<double> _animation;
  double _targetTemperature = 36.5;
  bool _isCreatingChat = false;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 인증 상태 확인
  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      // 로그인 모달 표시
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => LoginModalScreen(),
      );
      // 모달 닫힌 뒤에도 여전히 비로그인 상태라면 이전 화면으로 돌아감
      final newPrefs = await SharedPreferences.getInstance();
      final newToken = newPrefs.getString('token');
      if (newToken == null) {
        context.pop();
      } else {
        setState(() {}); // 로그인 후 화면 갱신
      }
    }
  }

  Future<Profile> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('로그인이 필요합니다');
    
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfileByUsername(widget.username)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      final profile = Profile.fromJson(json.decode(response.body));
      // 프로필 정보 받아온 후에 _controller.forward() 호출
      _targetTemperature = profile.temperature;
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
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
      print(data['maxParticipants']);
      print(data['currentParticipants']);
      Object result = context.push('/chat/${data['id']}');
      print(result);
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
                  SizedBox(height: 32),
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
                    title: Text('${profile.nickname}님이 쓴 피드'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // 해당 사용자의 피드 목록 화면으로 이동
                      context.push('/user/${profile.username}/feeds');
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  Spacer(),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                              "채팅방 생성 중...",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "1대1 채팅 시작하기",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
} 