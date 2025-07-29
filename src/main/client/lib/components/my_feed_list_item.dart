import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
                      onTap: () {
                        // 작성자의 프로필로 이동
                        final authorUsername = feed['authorUsername'];
                        if (authorUsername != null) {
                          context.push('/user/$authorUsername');
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
