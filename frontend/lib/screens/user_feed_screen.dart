import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';
import 'package:client/components/my_feed_list_item.dart';
import '../components/custom_app_bar.dart';
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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _feedsFuture = Future.value([]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndLoad();
    });
  }

  Future<void> _checkLoginAndLoad() async {
    final token = await _storage.read(key: 'token');
    
    if (token == null) {
      if (mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => LoginModalScreen(),
        );
        
        final newToken = await _storage.read(key: 'token');
        
        if (newToken == null) {
          if (mounted) context.pop();
        } else {
          await _loadFeeds(newToken);
        }
      }
    } else {
      await _loadFeeds(token);
    }
  }

  Future<void> _loadFeeds(String token) async {
    try {
      final feeds = await _fetchUserFeeds(token);
      if (mounted) {
        setState(() {
          _feedsFuture = Future.value(feeds);
        });
      }
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('403')) {
        if (mounted) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => LoginModalScreen(),
          );
          
          final newToken = await _storage.read(key: 'token');
          
          if (newToken != null) {
            await _loadFeeds(newToken);
          } else {
            if (mounted) context.pop();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _feedsFuture = Future.error(e);
          });
        }
      }
    }
  }

  Future<List<dynamic>> _fetchUserFeeds(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getUserFeeds(widget.username)}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('${response.statusCode}');
    } else {
      throw Exception('피드 정보를 불러오는 데 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        appBarType: AppBarType.close,
        title: Padding(
          padding: const EdgeInsets.only(left: 0, top: 4),
          child: Text(
            '피드',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _feedsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
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
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '작성한 피드가 없습니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF767676),
                ),
              ),
            );
          }

          final feeds = snapshot.data!;

          return Container(
            color: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: feeds.length,
              separatorBuilder: (context, index) => const Divider(
                thickness: 1,
                color: Color(0xFFE0E0E0),
              ),
              itemBuilder: (context, index) {
                return MyFeedListItem(feed: feeds[index]);
              },
            ),
          );
        },
      ),
    );
  }
} 