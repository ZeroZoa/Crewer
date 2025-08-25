import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';                // Flutter UI 라이브러리
import 'package:http/http.dart' as http;               // HTTP 요청을 위해 사용
import 'dart:convert';                                 // JSON 데이터 변환을 위해 사용
import 'package:lucide_icons/lucide_icons.dart';        // Lucide 아이콘 라이브러리
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../components/custom_app_bar.dart';

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
  bool _obscurePassword1 = true;  // 비밀번호 1 가시성
  bool _obscurePassword2 = true;  // 비밀번호 2 가시성

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
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.signup}'),
        headers: {'Content-Type': 'application/json'},       // JSON 형식으로 설정
        body: json.encode(formData),                         // 폼 데이터를 JSON으로 변환하여 전송
      );

      // 응답 상태 코드가 200인 경우 (회원가입 성공)
      if (response.statusCode == 200) {
        // 회원가입 성공 시 자동 로그인
        final FlutterSecureStorage _storage = const FlutterSecureStorage();
        await _storage.write(key: 'hasRegistered', value: 'true');
        
        // 자동 로그인 시도
        try {
          final loginResponse = await http.post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'username': _usernameController.text,
              'password': _password1Controller.text,
            }),
          );
          
          if (loginResponse.statusCode == 200) {
            final token = loginResponse.body;
            await _storage.write(key: 'token', value: token);
            
            setState(() {
              message = '회원가입이 완료되었습니다.';  // 성공 메시지 설정
              loading = false;  // 로딩 중지
            });
            context.go('/profile-setup');  // 프로필 설정 화면으로 이동
          } else {
            throw Exception('자동 로그인에 실패했습니다');
          }
        } catch (e) {
          setState(() {
            message = '회원가입은 완료되었지만 로그인에 실패했습니다. 다시 로그인해주세요.';  // 오류 메시지 설정
            loading = false;  // 로딩 중지
          });
          context.go('/login');  // 로그인 화면으로 이동
        }
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
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        appBarType: AppBarType.backOnly,
        title: Text(
          '회원가입',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // 상단 여백
              const SizedBox(height: 60),
              
              // 오류 또는 성공 메시지 표시
              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: message.contains('오류') ? Color(0xFFFF002B) : Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ),
              
              // 입력 필드들
              _buildTextField('닉네임', _nicknameController, '닉네임을 입력해주세요', Icons.person),
              const SizedBox(height: 20),
              _buildTextField('이메일', _usernameController, '이메일을 입력해주세요', Icons.email),
              const SizedBox(height: 20),
              _buildTextField('비밀번호', _password1Controller, '비밀번호를 입력해주세요', Icons.lock, obscureText: _obscurePassword1, onToggleVisibility: () {
                if (mounted) {
                  setState(() {
                    _obscurePassword1 = !_obscurePassword1;
                  });
                }
              }),
              const SizedBox(height: 20),
              _buildTextField('비밀번호 확인', _password2Controller, '비밀번호를 입력해주세요', Icons.lock, obscureText: _obscurePassword2, onToggleVisibility: () {
                if (mounted) {
                  setState(() {
                    _obscurePassword2 = !_obscurePassword2;
                  });
                }
              }),
              const SizedBox(height: 40),
              
              // 회원가입 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: loading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF002B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              // 하단 여백
              const SizedBox(height: 24),
              
              // 로그인 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '이미 계정이 있으신가요? ',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        color: Color(0xFFFF002B),
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              // 하단 여백
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 텍스트 필드 위젯 빌드 함수 (이미지에 맞게 수정)
  Widget _buildTextField(String label, TextEditingController controller, String hintText, IconData icon, {bool obscureText = false, VoidCallback? onToggleVisibility}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(
            fontSize: 14, 
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            suffixIcon: obscureText != null && onToggleVisibility != null ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onToggleVisibility,
            ) : null,
          ),
        ),
      ],
    );
  }
}