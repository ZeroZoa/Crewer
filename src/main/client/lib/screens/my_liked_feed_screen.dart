import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/components/my_feed_list_item.dart'; // 1단계에서 만든 위젯 import
import '../config/api_config.dart';

class MyLikedFeedScreen extends StatefulWidget {
  const MyLikedFeedScreen({super.key});

  @override
  State<MyLikedFeedScreen> createState() => _MyLikedFeedScreenState();
}

class _MyLikedFeedScreenState extends State<MyLikedFeedScreen> {
  late Future<List<dynamic>> _feedsFuture;

  @override
  void initState() {
    super.initState();
    _feedsFuture = _fetchLikedFeeds();
  }

  Future<List<dynamic>> _fetchLikedFeeds() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 실제 '좋아요한 글' API 엔드포인트로 수정해주세요.
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}/me/liked-feeds'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('좋아요한 피드를 불러오는 데 실패했습니다.');
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
          return const Center(child: Text('좋아요한 피드가 없습니다.'));
        }

        final feeds = snapshot.data!;
        return Container(
          color: Colors.white,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: feeds.length,
            separatorBuilder: (context, index) => const Divider(thickness: 1),
            itemBuilder: (context, index) {
              return MyFeedListItem(feed: feeds[index]);
            },
          ),
        );
      },
    );
  }
}
