import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 하단 네비게이션 바 컴포넌트
/// 현재 위치에 따라 선택된 탭을 표시하고, 선택 시 페이지를 이동합니다.
class BottomNavBar extends StatelessWidget {
  final String currentLocation; // 현재 페이지 경로를 전달받음

  const BottomNavBar({
    Key? key,
    required this.currentLocation,
  }) : super(key: key);

  /// 현재 경로와 동일할 경우 이동하지 않음 (불필요한 리렌더링 방지)
  void _navigate(BuildContext context, int index) {
    const routes = ['/', '/map', '/ranking', '/chat', '/profile']; // 하단 메뉴에 대응되는 경로 리스트
    final target = routes[index]; // 클릭된 탭에 해당하는 경로
    if (currentLocation != target) {
      context.push(target); // 페이지 이동
    }
  }

  @override
  Widget build(BuildContext context) {
    const routes = ['/', '/map', '/ranking', '/chat', '/profile'];
    final currentIndex = routes.indexOf(currentLocation);

    // BottomNavigationBar 위젯만 깔끔하게 반환
    return BottomNavigationBar(
      elevation: 0,
      backgroundColor: Colors.white,
      currentIndex: currentIndex < 0 ? 0 : currentIndex,
      onTap: (index) => _navigate(context, index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFFF002B),
      unselectedItemColor: const Color(0xFF767676),
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.mapPin),
          label: '지도',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.barChart2),
          label: '랭킹',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.messageCircle),
          label: '채팅',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.user),
          label: '마이페이지',
        ),
      ],
    );
  }
}
