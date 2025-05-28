import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 임포트
import 'package:client/components/login_modal_screen.dart'; // 로그인 모달 화면 임포트

/// 상단 네비게이션 바 컴포넌트
/// 로그인 상태를 스스로 체크하여 로그인 버튼 노출 여부를 결정합니다.
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
    _checkLoginStatus(); // 로그인 상태 초기 확인
  }

  // SharedPreferences에서 토큰 존재 여부로 로그인 상태 판단
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      // 토큰이 없으면 로그인 상태 아님
      setState(() => _isLoggedIn = false);
      return;
    }

    final parts = token.split('.');
    if (parts.length != 3) {
      // JWT 형식이 아니면 무효 처리
      setState(() => _isLoggedIn = false);
      return;
    }

    try {
      //JWT의 payload(중간 부분)를 디코딩하여 만료 시간 확인
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (exp is int && now < exp) {
        //아직 만료되지 않았으면 로그인 상태 유지
        setState(() => _isLoggedIn = true);
      } else {
        //만료되었으면 로그아웃 처리 (토큰 삭제)
        await prefs.remove('token');
        setState(() => _isLoggedIn = false);
      }
    } catch (e) {
      //디코딩 실패 시 무효 처리
      setState(() => _isLoggedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF9CB4CD)),
        onPressed: widget.onBack, //go
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
                // 모달 닫힌 후 다시 로그인 상태 갱신
                _checkLoginStatus();
              });
            },
          ),
      ],
    );
  }
}
