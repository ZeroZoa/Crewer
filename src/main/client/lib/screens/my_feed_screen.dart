import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:client/components/my_feed_list_item.dart'; // 1단계에서 만든 위젯 import
import '../components/custom_app_bar.dart';
import '../config/api_config.dart';

class MyFeedScreen extends StatefulWidget {
  const MyFeedScreen({super.key});

  @override
  State<MyFeedScreen> createState() => _MyFeedScreenState();
}

class _MyFeedScreenState extends State<MyFeedScreen> {
  late Future<List<dynamic>> _feedsFuture;

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _feedsFuture = _fetchMyFeeds();
  }

  Future<List<dynamic>> _fetchMyFeeds() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 실제 '내가 쓴 글' API 엔드포인트로 수정해주세요.
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}/me/feeds'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('내가 쓴 피드를 불러오는 데 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _feedsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('작성한 피드가 없습니다.'));
        }

        final feeds = snapshot.data!;
        return Scaffold(
          appBar: CustomAppBar(
            appBarType: AppBarType.close,
            title: Padding(
              // IconButton의 기본 여백과 비슷한 값을 줍니다.
              padding: const EdgeInsets.only(left: 0, top: 4),
              child: Text(
                '내가 쓴 피드',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
            ),
            actions: [],
          ),
          body: Container(
            color: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: feeds.length,
              separatorBuilder: (context, index) => const Divider(thickness: 1),
              itemBuilder: (context, index) {
                return MyFeedListItem(feed: feeds[index]);
              },
            ),
          ),
        );
      },
    );
  }
}
