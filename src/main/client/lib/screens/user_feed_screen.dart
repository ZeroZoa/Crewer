import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';
import 'package:client/components/my_feed_list_item.dart';
import '../config/api_config.dart';

/// 해당 사용자의 피드 목록 화면
/// • 로그인 상태가 아닌 경우 자동으로 로그인 모달을 띄워 접근을 제한합니다.
class UserFeedScreen extends StatefulWidget {
  final String username; // 조회할 사용자의 username

  const UserFeedScreen({Key? key, required this.username}) : super(key: key);

  @override
  _UserFeedScreenState createState() => _UserFeedScreenState();
}

class _UserFeedScreenState extends State<UserFeedScreen> {
  late Future<List<dynamic>> _feedsFuture;
  String? _userNickname;

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthentication());
    _feedsFuture = _fetchUserFeeds();
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

  Future<List<dynamic>> _fetchUserFeeds() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getUserFeeds(widget.username)}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final feeds = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      
      // 첫 번째 피드에서 사용자 닉네임 가져오기
      if (feeds.isNotEmpty) {
        _userNickname = feeds.first['authorNickname'];
      }
      
      return feeds;
    } else {
      throw Exception('피드 정보를 불러오는 데 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _feedsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 70, color: Color(0xFF9CB4CD)),
                  SizedBox(height: 16),
                  Text(
                    '작성한 피드가 없습니다.',
                    style: TextStyle(
                      color: Color(0xFF677888),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          final feeds = snapshot.data!;
          final nickname = _userNickname ?? widget.username;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: feeds.length,
            separatorBuilder: (context, index) => const Divider(thickness: 1),
            itemBuilder: (context, index) {
              final feed = feeds[index];
              return MyFeedListItem(feed: feed);
            },
          );
        },
      ),
    );
  }
} 