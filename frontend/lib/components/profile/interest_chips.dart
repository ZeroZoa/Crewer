import 'package:flutter/material.dart';

/// 관심사 칩 목록 표시 위젯 (읽기 전용)
/// 
/// 사용처: MyProfileScreen, UserProfileScreen
/// 
/// 사용 예시:
/// ```dart
/// InterestChips(
///   interests: ['가벼운 조깅', '정기적인 훈련'],
///   emptyMessage: '등록된 관심사가 없습니다.',
/// )
/// ```
class InterestChips extends StatelessWidget {
  /// 관심사 리스트
  final List<String>? interests;
  
  /// 빈 상태 메시지
  final String emptyMessage;
  
  /// 칩 간격 (기본값: 8)
  final double spacing;
  
  /// 줄 간격 (기본값: 8)
  final double runSpacing;

  const InterestChips({
    Key? key,
    required this.interests,
    this.emptyMessage = '등록된 관심사가 없습니다.',
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (interests == null || interests!.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Text(
          emptyMessage,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: interests!
            .map((interest) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFF002B),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      color: Color(0xFFFF002B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

