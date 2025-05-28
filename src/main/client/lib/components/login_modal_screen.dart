import 'package:flutter/material.dart'; // Flutter의 기본 위젯을 사용하기 위한 패키지
import 'package:http/http.dart' as http; // HTTP 요청/응답을 처리하기 위한 패키지
import 'dart:convert'; // JSON ↔ Dart 객체 변환을 위한 패키지
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 로컬 스토리지(SharedPreferences) 사용 패키지

// 로그인 모달 화면을 선언하는 StatefulWidget 클래스
class LoginModalScreen extends StatefulWidget {
  @override
  _LoginModalScreenState createState() => _LoginModalScreenState();
}

// 실제 상태(state)와 로직을 구현하는 클래스
class _LoginModalScreenState extends State<LoginModalScreen> {
  final TextEditingController usernameController = TextEditingController(); // 아이디 입력 컨트롤러
  final TextEditingController passwordController = TextEditingController(); // 비밀번호 입력 컨트롤러
  bool _loading = false; // 로그인 요청 중 로딩 상태를 나타내는 플래그

  @override
  void dispose() {
    // 위젯이 소멸될 때 컨트롤러 해제
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 로그인 버튼 클릭 시 호출되는 비동기 함수
  Future<void> _onLogin() async {
    setState(() {
      _loading = true; // 로딩 시작
    });
    try {
      // HTTP POST 요청 보내기 (Android 에뮬레이터의 로컬호스트 경로)
      final response = await http.post(
        //Uri.parse('http://10.0.2.2:8080/members/login'),
        Uri.parse('http://localhost:8080/members/login'),
        headers: {'Content-Type': 'application/json'}, // JSON 형식 요청 헤더
        body: jsonEncode({
          'username': usernameController.text.trim(), // 아이디 값
          'password': passwordController.text.trim(), // 비밀번호 값
        }),
      );
      // 응답 코드가 200이 아니면 예외 처리
      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
      // 응답 본문(토큰) 가져오기
      final token = response.body;
      // SharedPreferences 인스턴스 획득
      final prefs = await SharedPreferences.getInstance();
      // 토큰 저장
      await prefs.setString('token', token);

      // 로그인 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 성공')),
      );
      // 모달 닫기
      context.pop();
      // 홈 화면으로 이동
      context.go('/');
    } catch (e) {
      // 로그인 실패 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _loading = false; // 로딩 종료
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI를 그려주는 LoginModal 위젯으로 전달
    return LoginModal(
      usernameController: usernameController, // 아이디 컨트롤러
      passwordController: passwordController, // 비밀번호 컨트롤러
      onLogin: _loading ? null : _onLogin, // 로딩 중이면 버튼 비활성화
    );
  }
}

// 로그인/회원가입 모달의 UI 위젯
class LoginModal extends StatelessWidget {
  final TextEditingController usernameController; // 아이디 입력 컨트롤러
  final TextEditingController passwordController; // 비밀번호 입력 컨트롤러
  final VoidCallback? onLogin; // 로그인 버튼 콜백

  const LoginModal({
    Key? key,
    required this.usernameController,
    required this.passwordController,
    required this.onLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.5, // 모달 높이를 화면의 50%로 설정
      child: Container(
        padding: EdgeInsets.all(20), // 내부 여백
        decoration: BoxDecoration(
          color: Colors.white, // 배경색 흰색
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)), // 상단만 둥글게
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 자식 크기만큼 축소
          children: [
            // 제목 텍스트
            Text(
              '로그인/회원가입',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CB4CD), // 메인 컬러
              ),
            ),
            SizedBox(height: 20), // 간격
            // 아이디 입력 필드
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: '아이디(이메일)',
                prefixIcon: Icon(Icons.person),
                filled: true,
                fillColor: Color(0xF2E4E7EA), // 배경색 지정
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 14.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), // 모서리 둥글게
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 12), // 간격
            // 비밀번호 입력 필드
            TextField(
              controller: passwordController,
              obscureText: true, // 비밀번호 가리기
              decoration: InputDecoration(
                labelText: '비밀번호',
                prefixIcon: Icon(Icons.lock),
                filled: true,
                fillColor: Color(0xF2E4E7EA),
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 14.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 20), // 간격
            // 로그인 버튼
            ElevatedButton(
              onPressed: onLogin, // 콜백 함수 호출
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF9CB4CD), // 버튼 배경색
                minimumSize: Size(double.infinity, 50), // 넓이 꽉 채우기, 높이 50
              ),
              child: onLogin == null
                  ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2), // 로딩 인디케이터
              )
                  : Text(
                  '로그인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
              ),
            ),
            SizedBox(height: 12), // 간격
            // 회원가입 페이지 이동 링크
            GestureDetector(
              onTap: () => context.push('/signup'),
              child: Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: RichText(
                  text: TextSpan(
                    text: '아직 계정이 없으신가요?  ',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                    children: [
                      TextSpan(
                        text: '회원가입',
                        style: TextStyle(
                          color: Color(0xFF9CB4CD),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline, // 밑줄 표시
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
