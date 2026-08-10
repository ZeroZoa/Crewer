import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../components/custom_app_bar.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController(); // 이메일
  final TextEditingController _password1Controller = TextEditingController();
  final TextEditingController _password2Controller = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController(); // 인증 코드

  // 상태 변수
  String _message = ''; // 결과 메시지
  bool _isLoading = false;  // 하나의 로딩 상태 변수
  bool _isCodeSent = false; // 인증 코드 발송 성공 여부
  bool _isVerified = false; // 인증 완료 여부
  String? _verifiedToken;
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;



  Future<void> _handleSignup() async {
    if (!mounted) return;
    setState(() {
      _message = '';
      _isLoading = true;
    });

    // 비밀번호 길이 확인
    if (_password1Controller.text.length < 8) {
      if (!mounted) return;
      setState(() {
        _message = '비밀번호는 최소 8자 이상이어야 합니다.';
        _isLoading = false;
      });
      return;
    }

    // 비밀번호와 비밀번호 확인의 동일성 확인
    if (_password1Controller.text != _password2Controller.text) {
      if (!mounted) return;
      setState(() {
        _message = '비밀번호가 일치하지 않습니다.';
        _isLoading = false;
      });
      return;
    }

    // 인증 유무 확인
    if(_verifiedToken == null){
      setState(() {
        _message = '이메일을 인증해주세요.';
        _isLoading = false;
      });
      return;
    }

    final nickname = _nicknameController.text.trim();

    // 1. 빈 문자열 체크
    if (nickname.isEmpty) {
      setState(() {
        _message = '닉네임을 입력해주세요.';
        _isLoading = false;
      });
      return;
    }

    // 2. 길이 체크
    if (nickname.length < 2 || nickname.length > 10) {
      setState(() {
        _message = '닉네임은 2자 이상 10자 이하여야 합니다.';
        _isLoading = false;
      });
      return;
    }

    // 3. 형식 체크 (공백 포함 거부)
    final nicknamePattern = RegExp(r'^[가-힣a-zA-Z0-9]+$');
    if (!nicknamePattern.hasMatch(nickname)) {
      setState(() {
        _message = '닉네임은 한글, 영문, 숫자만 사용할 수 있으며, 공백은 포함할 수 없습니다.';
        _isLoading = false;
      });
      return;
    }

    final Map<String, String> formData = {
      'username': _usernameController.text.trim(),
      'password1': _password1Controller.text,
      'password2': _password2Controller.text,
      'verifiedToken': _verifiedToken!,
      'nickname': nickname,  // trim된 닉네임 사용
    };



    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getSignup()}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formData),
      );


      final responseBody = json.decode(utf8.decode(response.bodyBytes)); // 한글 깨짐 방지

      if (response.statusCode == 200) {
        // 회원가입 성공 시 자동 로그인
        final FlutterSecureStorage _storage = const FlutterSecureStorage();
        await _storage.write(key: 'hasRegistered', value: 'true');
        
        // 자동 로그인 시도
        try {
          final loginResponse = await http.post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getLogin()}'),
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
              _message = '회원가입이 완료되었습니다.';  // 성공 메시지 설정
              _isLoading = false;  // 로딩 중지
            });
            context.go('/profile-setup');  // 프로필 설정 화면으로 이동
          } else {
            throw Exception('자동 로그인에 실패했습니다');
          }
        } catch (e) {
          setState(() {
            _message = '회원가입은 완료되었지만 로그인에 실패했습니다. 다시 로그인해주세요.';  // 오류 메시지 설정
            _isLoading = false;  // 로딩 중지
          });
          context.go('/login');  // 로그인 화면으로 이동
        }
      } else {
        setState(() {
          _message = responseBody['message'] ?? '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
        });
      }
    } catch (e) {
      setState(() {
        _message = '네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 인증 코드 발송 로직
  Future<void> _handleSendVerificationCode() async {
    if (!mounted) return;
    final email = _usernameController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 주소를 먼저 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getSendVerificationCode()}').replace(
            queryParameters: {'email': email},
          )
      );


      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증 코드가 이메일로 발송되었습니다.')),
        );
        setState(() {
          _isCodeSent = true;
        });
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] ?? '알 수 없는 오류가 발생했습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $errorMessage')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드 발송 중 오류가 발생했습니다.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVerifyCode() async {
    if (!mounted) return;
    final email = _usernameController.text.trim();
    final code = _verificationCodeController.text.trim();

    if (email.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 인증 코드를 모두 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getVerifyCode()}').replace(
            queryParameters: {
              'email': email,
              'code': code,
            },
          )
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증이 완료되었습니다.')),
        );

        setState(() {
          _isVerified = true;
          _verifiedToken = responseBody['verifiedToken'];
        });

      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] ?? '인증 코드가 일치하지 않거나 만료되었습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드 확인 중 오류가 발생했습니다.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        appBarType: AppBarType.backOnly,
        title: const Text('회원가입', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView( // 키보드가 올라올 때 화면이 깨지지 않도록 스크롤 추가
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      '이메일',
                      _usernameController,
                      '이메일을 입력해주세요.',
                      Icons.email,
                      // (수정) _isCodeSent 값에 따라 읽기 전용으로 설정
                      enabled: !_isCodeSent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        minimumSize: const Size(0, 60),
                        // (수정) _isCodeSent 값에 따라 배경색 변경
                        backgroundColor: _isCodeSent ? Colors.grey : const Color(0xFFFF002B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      // (수정) _isCodeSent가 true이면 버튼 비활성화
                      onPressed: _isLoading || _isCodeSent ? null : _handleSendVerificationCode,
                      child: const Text('인증요청', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ],
              ),


              if (_isCodeSent)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            '인증코드',
                            _verificationCodeController,
                            '인증코드를 입력해주세요.',
                            Icons.shield_moon,
                            enabled: !_isVerified,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 32.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              minimumSize: const Size(0, 60),
                              backgroundColor: _isVerified ? Colors.grey : const Color(0xFFFF002B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _isLoading || _isVerified ? null : _handleVerifyCode,
                            child: Text(
                              _isVerified ? '인증완료' : '인증확인',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 인증이 완료되면 보이는 성공 메시지
                    if (_isVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              '이메일 인증이 완료되었습니다.',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 20),
              _buildTextField('비밀번호', _password1Controller, '8자 이상 입력해주세요.', Icons.lock, obscureText: _obscurePassword1, onToggleVisibility: () {
                if (mounted) setState(() => _obscurePassword1 = !_obscurePassword1);
              }),
              const SizedBox(height: 20),
              _buildTextField('비밀번호 확인', _password2Controller, '비밀번호를 다시 입력해주세요.', Icons.lock, obscureText: _obscurePassword2, onToggleVisibility: () {
                if (mounted) setState(() => _obscurePassword2 = !_obscurePassword2);
              }),
              const SizedBox(height: 20),
              _buildTextField('닉네임', _nicknameController, '2-10자, 한글/영문/숫자만 가능', Icons.person),
              const SizedBox(height: 20),
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _message.contains('오류') || _message.contains('실패') || _message.contains('일치하지') 
                          ? const Color(0xFFFF002B) 
                          : Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFFF002B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                      : const Text('회원가입', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('이미 계정이 있으신가요? ', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('로그인', style: TextStyle(color: Color(0xFFFF002B), fontSize: 14, decoration: TextDecoration.underline, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      String hintText,
      IconData icon,
      {
        bool obscureText = false,
        VoidCallback? onToggleVisibility,
        bool enabled = true
      }) {
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
          enabled: enabled,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            suffixIcon: onToggleVisibility != null
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}