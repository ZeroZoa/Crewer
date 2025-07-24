import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 토큰 확인/삭제
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';   // 로그인 모달 화면


/// 마이 프로필 화면
/// • 로그인 상태가 아닌 경우 자동으로 로그인 모달을 띄워 접근을 제한합니다.
class MyProfileScreen extends StatefulWidget {
  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _loading = true;
  bool _error = false;

  @override


  void initState() {
    super.initState();
    _loadData();
    // 첫 빌드 후 인증 확인
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthentication());
  }

  /// 인증 상태 확인
  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      // 로그인 모달 표시
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => LoginModalScreen(),
      );
      // 모달 닫힌 뒤에도 여전히 비로그인 상태라면 이전 화면으로 돌아감
      final newToken = prefs.getString('token');
      if (newToken == null) {
        context.pop();
      } else {
        setState(() {}); // 로그인 후 화면 갱신
      }
    }
  }

  Future<void> _loadData() async{
    setState(() => _loading = true);
    await Future.wait([
      _fetchMemberInfo(),
    ]);
    setState(() => _loading = false);
  }

  Future<void> _fetchMemberInfo() async {
    // try {
    //   final resp = await http.get(
    //     Uri.parse('http://localhost:8080/feeds/')
    //   );
    //   if(resp.statusCode == 200){
    //
    //   }
    // }
  }

  /// 로그아웃 처리: 토큰 삭제 후 홈으로 이동
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 100,
            padding: const EdgeInsets.all(16),

          ),
          Divider(thickness: 5,),
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF9CB4CD),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text('로그아웃', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
