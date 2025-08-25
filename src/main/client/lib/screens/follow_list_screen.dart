import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/follow_service.dart';
import '../models/member.dart';
import '../components/custom_app_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class FollowListScreen extends StatefulWidget {
  final String username;
  final bool isFollowers;

  const FollowListScreen({
    Key? key,
    required this.username,
    required this.isFollowers,
  }) : super(key: key);

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<Member> _followList = [];
  Map<String, bool> _isFollowedByMe = {};
  bool _isLoading = true;
  String? _error;
  bool _isMyProfile = false;
  Map<String, bool> _isCreatingChat = {}; // 메시지 버튼 로딩 상태

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkIfMyProfile();
    _loadFollowList();
  }

  // 내 프로필인지 확인
  Future<void> _checkIfMyProfile() async {
    // username이 'me'이거나 현재 로그인한 사용자와 같으면 내 프로필
    _isMyProfile = widget.username == 'me';
  }

  Future<void> _loadFollowList() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      List<Map<String, dynamic>> list;
      if (widget.isFollowers) {
        list = await FollowService.getFollowers(widget.username);
      } else {
        list = await FollowService.getFollowing(widget.username);
      }

      // Map을 Member 객체로 변환
      List<Member> users = list.map((json) => Member.fromJson(json)).toList();

      Map<String, bool> isFollowedByMe = {};
      
      if (_isMyProfile) {
              for (var member in users) {
        try {
          final status = await FollowService.checkFollowStatus(member.username);
          isFollowedByMe[member.username] = status['isFollowing'] ?? false;
        } catch (e) {
          isFollowedByMe[member.username] = false;
        }
      }
      }

      setState(() {
        _followList = users;
        _isFollowedByMe = isFollowedByMe;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 1대1 채팅방 생성
  Future<void> _createDirectChat(String username) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('로그인이 필요합니다');
    if (_isCreatingChat[username] == true) return;
    
    setState(() => _isCreatingChat[username] = true);
    
    try {
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getJoinDirectChat(username)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        context.push('/chat/${data['id']}');
      } else {
        throw Exception('채팅방 생성에 실패했습니다');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방 생성 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() => _isCreatingChat[username] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarType: AppBarType.backWithMore,
        title: Text(
          widget.isFollowers ? '팔로워' : '팔로잉',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        onNotificationPressed: () {
          // TODO: 더보기 기능 구현
        },
      ),
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9CB4CD),
        ),
      );
    }

    if (_error != null) {
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
            Text(
              '오류가 발생했습니다',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFollowList,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9CB4CD),
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_followList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isFollowers ? Icons.people_outline : Icons.person_outline,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              widget.isFollowers ? '팔로워가 없습니다' : '팔로잉이 없습니다',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isFollowers
                  ? '아직 이 사용자를 팔로우하는 사람이 없습니다'
                  : '아직 이 사용자가 팔로우하는 사람이 없습니다',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowList,
      color: const Color(0xFF9CB4CD),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _followList.length,
        itemBuilder: (context, index) {
          final user = _followList[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  Widget _buildUserTile(Member user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[400],
                      backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
              ? Text(
                  user.username.isNotEmpty
                      ? user.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        title: Text(
          // 닉네임이 있으면 닉네임, 없으면 유저네임 표시
          user.nickname ?? user.username,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: user.nickname != null && user.nickname != user.username
            ? Text(
                user.username,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              )
            : null,
        trailing: _isMyProfile ? _buildFollowButton(user) : null,
        onTap: () async {
          // 현재 사용자의 username 가져오기
          final token = await _storage.read(key: _tokenKey);
          String? currentUsername;
          
          if (token != null) {
            try {
              final response = await http.get(
                Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfileMe()}'),
                headers: {'Authorization': 'Bearer $token'},
              );
              if (response.statusCode == 200) {
                final profile = json.decode(response.body);
                currentUsername = profile['username'];
              }
            } catch (e) {
              print('현재 사용자 정보 로드 실패: $e');
            }
          }
          
          // 현재 사용자인지 확인하여 적절한 페이지로 이동
          if (currentUsername == user.username) {
            context.push('/me'); // 내 프로필
          } else {
            context.push('/user/${user.username}'); // 다른 사용자 프로필
          }
        },
      ),
    );
  }

  Widget? _buildFollowButton(Member user) {
    final isFollowedByMe = _isFollowedByMe[user.username] ?? false;
    
    // 팔로워 리스트인 경우: 맞팔로우 상태일 때만 언팔로우 버튼 표시
    // 팔로잉 리스트인 경우: 언팔로우 버튼 표시
    String buttonText;
    Color buttonColor;
    Color textColor;
    BorderSide? borderSide;
    
    if (widget.isFollowers) {
      // 팔로워 리스트 - 팔로우 상태에 따라 버튼 결정
      if (isFollowedByMe) {
        // 내가 팔로우한 상태 - 언팔로우 버튼
        buttonText = '언팔로우';
        buttonColor = Colors.grey[300]!;
        textColor = Colors.black;
        borderSide = BorderSide(color: Colors.grey[400]!, width: 1);
      } else {
        // 내가 팔로우하지 않은 상태 - 맞팔로우 버튼
        buttonText = '맞팔로우';
        buttonColor = const Color(0xFFFF002B);
        textColor = Colors.white;
        borderSide = null;
      }
    } else {
      // 팔로잉 리스트 - 언팔로우 버튼
      buttonText = '언팔로우';
      buttonColor = Colors.grey[300]!;
      textColor = Colors.black;
      borderSide = BorderSide(color: Colors.grey[400]!, width: 1);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 팔로우/언팔로우 버튼
        Container(
          height: 32,
          child: ElevatedButton(
            onPressed: () async {
              try {
                if (widget.isFollowers) {
                  // 팔로워 리스트에서의 동작 - 팔로우 상태에 따라 동작 결정
                  if (isFollowedByMe) {
                    // 내가 팔로우한 상태 - 언팔로우
                    await FollowService.unfollowUser(user.username);
                    setState(() {
                      _isFollowedByMe[user.username] = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('언팔로우했습니다'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    // 내가 팔로우하지 않은 상태 - 맞팔로우
                    await FollowService.followUser(user.username);
                    setState(() {
                      _isFollowedByMe[user.username] = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('맞팔로우했습니다'),
                        backgroundColor: Color(0xFF9CB4CD),
                      ),
                    );
                  }
                } else {
                  // 팔로잉 리스트에서의 동작 - 언팔로우만 가능
                  await FollowService.unfollowUser(user.username);
                  setState(() {
                    _isFollowedByMe[user.username] = false;
                    // 팔로잉 리스트에서 해당 사용자 제거
                    _followList.removeWhere((u) => u.username == user.username);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('언팔로우했습니다'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('오류: $e'),
                    backgroundColor: Color(0xFFFF002B),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: textColor,
              side: borderSide,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        // 메시지 버튼
        Container(
          height: 32,
          child: ElevatedButton(
            onPressed: _isCreatingChat[user.username] == true ? null : () => _createDirectChat(user.username),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300]!,
              foregroundColor: Colors.black,
              side: BorderSide(color: Colors.grey[400]!, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: _isCreatingChat[user.username] == true
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    '메시지',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
} 