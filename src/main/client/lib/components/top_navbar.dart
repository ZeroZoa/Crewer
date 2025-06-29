import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/components/login_modal_screen.dart';

/// 상단 네비게이션 바 컴포넌트
class TopNavBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;

  const TopNavBar({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  _TopNavBarState createState() => _TopNavBarState();

  @override
  Size get preferredSize => const Size.fromHeight(56); // AppBar 높이 고정
}

class _TopNavBarState extends State<TopNavBar> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// 외부에서 로그인 상태를 확인하고 싶을 경우 사용 가능한 정적 메서드
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final parts = token.split('.');
    if (parts.length != 3) return false;

    try {
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return (exp is int && now < exp);
    } catch (_) {
      return false;
    }
  }

  /// 현재 로그인 상태를 내부적으로 확인하여 UI 갱신
  Future<void> _checkLoginStatus() async {
    final result = await _TopNavBarState.isUserLoggedIn();
    setState(() => _isLoggedIn = result);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF9CB4CD)),
        onPressed: widget.onBack,
      ),
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: const Text(
          'Crewer',
          style: TextStyle(
            fontFamily: 'CustomFont',
            color: Color(0xFF9CB4CD),
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        if (!_isLoggedIn)
          IconButton(
            icon: const Icon(LucideIcons.logIn, color: Color(0xFF9CB4CD)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => LoginModalScreen(),
              ).then((_) {
                _checkLoginStatus(); // 모달 닫힌 뒤 상태 재확인
              });
            },
          ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
        ),
      ),
    );
  }
}
