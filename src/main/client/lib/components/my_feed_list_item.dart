import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

// 날짜 포맷팅 헬퍼 함수
String formatDate(String iso) {
  try {
    final d = DateTime.parse(iso);
    return '${d.year}년 ${d.month}월 ${d.day}일';
  } catch (e) {
    return '날짜 정보 없음';
  }
}

// 제목 자르기 헬퍼 함수
String truncate(String text, int length) =>
    text.length > length ? '${text.substring(0, length)}...' : text;

class MyFeedListItem extends StatelessWidget {
  final Map<String, dynamic> feed;

  const MyFeedListItem({super.key, required this.feed});

  @override
  Widget build(BuildContext context) {
    // groupfeed인지 일반 feed인지 확인
    final isGroup = feed.containsKey('chatRoomId');
    final feedId = feed['id'];

    return GestureDetector(
      onTap: () {
        final route = isGroup ? '/groupfeeds/$feedId' : '/feeds/$feedId';
        context.push(route);
      },
      child: Container(
        color: Colors.white, // 배경색을 명확히 지정하여 탭 영역 보장
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  truncate(feed['title'] ?? '제목 없음', 13),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isGroup)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9CB4CD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '# 모여요',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${formatDate(feed['createdAt'] ?? '')} · ',
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: () async {
                        // 작성자의 프로필로 이동
                        final authorUsername = feed['authorUsername'];
                        if (authorUsername != null) {
                          // 현재 사용자의 username 가져오기
                          final prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('token');
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
                          if (currentUsername == authorUsername) {
                            context.push('/profile'); // 내 프로필
                          } else {
                            context.push('/user/$authorUsername'); // 다른 사용자 프로필
                          }
                        }
                      },
                      child: Text(
                        feed['authorNickname'] ?? '알 수 없음',
                        style: TextStyle(
                          color: Colors.grey.shade800, 
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(LucideIcons.heart, color: Colors.red, size: 17),
                    const SizedBox(width: 2),
                    Text('${feed['likesCount'] ?? 0}'),
                    const SizedBox(width: 10),
                    const Icon(
                      LucideIcons.messageCircle,
                      color: Colors.blue,
                      size: 17,
                    ),
                    const SizedBox(width: 3),
                    Text('${feed['commentsCount'] ?? 0}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
