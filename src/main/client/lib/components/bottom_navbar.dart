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
    const routes = ['/', '/map', '/ranking', '/chat', '/profile']; // 하단 탭 라우트 기준
    final currentIndex = routes.indexOf(currentLocation); // 현재 경로가 몇 번째 탭인지 확인
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        //Divider(height: 1, thickness: 1), //디바이더 없애도 됨 추후에, Column도 같이
        ColoredBox(
        color: Colors.white,
        child: SizedBox(
          height: screenHeight * 0.09,
          child: Align(
            alignment: Alignment.topCenter,
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.white,
              currentIndex: currentIndex < 0 ? 0 : currentIndex, // 유효하지 않으면 홈(0)으로 설정
              onTap: (index) => _navigate(context, index), // 탭 클릭 시 페이지 이동
              type: BottomNavigationBarType.fixed, // 모든 아이템 고정 표시
              selectedItemColor: const Color(0xFFFF002B), // 선택된 아이템 색상
              unselectedItemColor: const Color(0xFF767676), // 선택되지 않은 아이템 색상
              showUnselectedLabels: true, // 선택되지 않은 라벨도 보여줌
              items: [
                  BottomNavigationBarItem(
                    icon: Icon(
                      LucideIcons.home,
                      color: currentLocation == '/' ? Color(0xFFFF002B) : Color(0xFF767676), // 현재 페이지이면 검정색
                    ),
                    label: '홈',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                     LucideIcons.mapPin,
                     color: currentLocation == '/map' ? Color(0xFFFF002B) : Color(0xFF767676),
                    ),
                    label: '지도',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      LucideIcons.barChart2,
                      color: currentLocation == '/ranking' ? Color(0xFFFF002B) : Color(0xFF767676),
                    ),
                    label: '랭킹',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      LucideIcons.messageCircle,
                      color: currentLocation == '/chat' ? Color(0xFFFF002B) : Color(0xFF767676),
                    ),
                    label: '채팅',
                  ),
                 BottomNavigationBarItem(
                    icon: Icon(
                      LucideIcons.user,
                      color: currentLocation == '/profile' ? Color(0xFFFF002B) : Color(0xFF767676),
                    ),
                    label: '마이페이지',
                 ),
               ],
              )
            )
          )
        )
      ]
    );
  }
}
