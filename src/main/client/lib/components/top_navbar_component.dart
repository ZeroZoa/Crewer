import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/components/login_modal_screen.dart';

/// 범용 상단 네비게이션바 슬롯 기반 컴포넌트
/// - [leading]: 왼쪽에 들어갈 위젯 (보통 뒤로가기 버튼)
/// - [title]: 중앙에 들어갈 위젯 (로고나 제목)
/// - [actions]: 오른쪽에 들어갈 위젯 리스트
class CustomNavBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget leading;
  final Widget title;
  final List<Widget> actions;

  const CustomNavBar({
    Key? key,
    required this.leading,
    required this.title,
    this.actions = const [],
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: leading,
      title: title,
      centerTitle: true,
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1),
      ),
    );
  }
}

/// 로그인 여부 체크용 헬퍼
Future<bool> isUserLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) return false;

  final parts = token.split('.');
  if (parts.length != 3) return false;

  try {
    final payload = json.decode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    ) as Map<String, dynamic>;
    final exp = payload['exp'] as int? ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now < exp;
  } catch (_) {
    return false;
  }
}

/// 실제 사용 예시
class TopNavBarExample extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;

  const TopNavBarExample({Key? key, required this.onBack}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  _TopNavBarExampleState createState() => _TopNavBarExampleState();
}

class _TopNavBarExampleState extends State<TopNavBarExample> {
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _refreshLogin();
  }

  Future<void> _refreshLogin() async {
    final ok = await isUserLoggedIn();
    if (mounted) setState(() => _loggedIn = ok);
  }

  @override
  Widget build(BuildContext context) {
    return CustomNavBar(
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
      actions: [
        if (!_loggedIn)
          IconButton(
            icon: const Icon(LucideIcons.logIn, color: Color(0xFF9CB4CD)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => LoginModalScreen(),
              ).then((_) => _refreshLogin());
            },
          ),
      ],
    );
  }
}