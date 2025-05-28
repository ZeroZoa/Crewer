import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

// 하단 네비게이션바 컴포넌트
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  // 현재 라우트를 얻어옵니다.
  String _currentRoute(BuildContext context) {
    return ModalRoute.of(context)?.settings.name ?? '/';
  }

  // 인덱스에 따라 해당 경로로 이동합니다.
  void _navigate(BuildContext context, int index) {
    const routes = ['/', '/map', '/ranking', '/chat', '/profile'];
    final target = routes[index];
    final current = _currentRoute(context);
    if (current != target) {
      context.push(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentRoute(context);
    final currentIndex = ['/', '/map', '/ranking', '/chat', '/profile']
        .indexOf(current);

    return BottomNavigationBar(
      currentIndex: currentIndex < 0 ? 0 : currentIndex,
      onTap: (index) => _navigate(context, index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: const Color(0xFF9CB4CD),
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            LucideIcons.home,
            color: current == '/' ? Colors.black : Color(0xFF9CB4CD),
          ),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            LucideIcons.mapPin,
            color: current == '/map' ? Colors.black : Color(0xFF9CB4CD),
          ),
          label: '지도',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            LucideIcons.barChart2,
            color: current == '/ranking' ? Colors.black : Color(0xFF9CB4CD),
          ),
          label: '랭킹',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            LucideIcons.messageCircle,
            color: current == '/chat' ? Colors.black : Color(0xFF9CB4CD),
          ),
          label: '채팅',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            LucideIcons.user,
            color: current == '/profile' ? Colors.black : Color(0xFF9CB4CD),
          ),
          label: '프로필',
        ),
      ],
    );
  }
}
