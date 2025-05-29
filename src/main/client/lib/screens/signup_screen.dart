import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';                // Flutter UI 라이브러리
import 'package:http/http.dart' as http;               // HTTP 요청을 위해 사용
import 'dart:convert';                                 // JSON 데이터 변환을 위해 사용
import 'package:lucide_icons/lucide_icons.dart';        // Lucide 아이콘 라이브러리

// 회원가입 화면을 담당하는 StatefulWidget 클래스
class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();  // 상태 관리 객체를 생성
}

// 상태를 관리하는 클래스
class _SignupScreenState extends State<SignupScreen> {
  // 입력 필드 컨트롤러 선언
  final TextEditingController _usernameController = TextEditingController();  // 아이디 입력
  final TextEditingController _password1Controller = TextEditingController(); // 비밀번호 입력
  final TextEditingController _password2Controller = TextEditingController(); // 비밀번호 확인 입력
  final TextEditingController _nicknameController = TextEditingController();  // 닉네임 입력

  // 상태 변수
  String message = '';        // 회원가입 처리 결과 메시지
  bool loading = false;       // 로딩 상태 여부

  // 회원가입 버튼 클릭 시 호출되는 메서드
  Future<void> _signup() async {
    setState(() {
      message = '';   // 메시지 초기화
      loading = true; // 로딩 시작
    });

    // 비밀번호 일치 여부 확인
    if (_password1Controller.text != _password2Controller.text) {
      setState(() {
        message = '비밀번호가 일치하지 않습니다.';  // 오류 메시지 설정
        loading = false;  // 로딩 중지
      });
      return;  // 함수 종료
    }

    // 폼 데이터 Map으로 생성
    final Map<String, String> formData = {
      'username': _usernameController.text,
      'password1': _password1Controller.text,
      'password2': _password2Controller.text,
      'nickname': _nicknameController.text,
    };

    try {
      // 서버로 POST 요청 보내기
      final response = await http.post(
        Uri.parse('http://localhost:8080:8080/members/register'), // 에뮬레이터용 로컬호스트
        //Uri.parse('http://10.0.2.2:8080/members/register'), // 에뮬레이터용 로컬호스트
        headers: {'Content-Type': 'application/json'},       // JSON 형식으로 설정
        body: json.encode(formData),                         // 폼 데이터를 JSON으로 변환하여 전송
      );

      // 응답 상태 코드가 200인 경우 (회원가입 성공)
      if (response.statusCode == 200) {
        setState(() {
          message = '회원가입이 완료되었습니다.';  // 성공 메시지 설정
          loading = false;  // 로딩 중지
        });
        context.go('/');  // 메인 페이지로 이동
      } else {
        setState(() {
          message = '회원가입 오류: ${response.body}';  // 오류 메시지 설정
          loading = false;  // 로딩 중지
        });
      }
    } catch (e) {
      // 예외 발생 시 오류 처리
      setState(() {
        message = '회원가입 중 오류가 발생했습니다: $e';  // 예외 메시지 설정
        loading = false;  // 로딩 중지
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 본문 구성
      body: Padding(
        padding: const EdgeInsets.all(16.0),               // 전체 패딩 설정
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,      // 오른쪽 정렬
          children: [
            // 회원가입 독려 문구
            Text(
              '회원가입하고 \n함께 달리기!',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CB4CD),  // 메인 컬러
              ),
            ),
            const SizedBox(height: 20),  // 문구와 입력필드 간 간격
            // 오류 또는 성공 메시지 표시
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  message,
                  style: TextStyle(
                    color: message.contains('오류') ? Colors.red : Colors.green,
                  ),
                ),
              ),
            // 입력 필드들
            _buildTextField('이메일 (아이디)', _usernameController, 'abc@abc.com', LucideIcons.mail),
            _buildTextField('비밀번호', _password1Controller, '8자 이상 입력해주세요.', LucideIcons.lock, obscureText: true),
            _buildTextField('비밀번호 확인', _password2Controller, '비밀번호 확인을 입력해주세요.', LucideIcons.check, obscureText: true),
            _buildTextField('닉네임', _nicknameController, '3자 이상 입력해주세요.', LucideIcons.user),
            const SizedBox(height: 20),
            // 회원가입 버튼
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF9CB4CD),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  '회원가입',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 텍스트 필드 위젯 빌드 함수 (아이콘 추가)
  Widget _buildTextField(String label, TextEditingController controller, String hintText, IconData icon, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.black)),
          SizedBox(height: 4),
          TextField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey),
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Color(0xF2E4E7EA),
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
