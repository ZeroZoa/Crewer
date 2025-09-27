import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../components/custom_app_bar.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _loading = false;
  bool _showLoginForm = false;
  bool _obscurePassword = true;
  bool _saveId = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 저장된 이메일 불러오기
  Future<void> _loadSavedEmail() async {
    try {
      final savedEmail = await _secureStorage.read(key: 'saved_email');
      final saveIdChecked = await _secureStorage.read(key: 'save_id_checked');
      
      if (savedEmail != null && saveIdChecked == 'true') {
        setState(() {
          emailController.text = savedEmail;
          _saveId = true;
        });
      }
    } catch (e) {
      print('저장된 이메일 불러오기 실패: $e');
    }
  }

  // 이메일 저장/삭제
  Future<void> _saveEmail() async {
    try {
      if (_saveId && emailController.text.isNotEmpty) {
        await _secureStorage.write(key: 'saved_email', value: emailController.text);
        await _secureStorage.write(key: 'save_id_checked', value: 'true');
      } else {
        await _secureStorage.delete(key: 'saved_email');
        await _secureStorage.write(key: 'save_id_checked', value: 'false');
      }
    } catch (e) {
      print('이메일 저장 실패: $e');
    }
  }

  void _toggleLoginForm() {
    setState(() {
      _showLoginForm = !_showLoginForm;
    });
  }

  void _goBack() {
    setState(() {
      _showLoginForm = false;
    });
  }

  Future<void> _onLogin() async {
    setState(() => _loading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (mounted) {
      if (success) {
        // 로그인 성공 시 hasRegistered를 true로 설정
        await _secureStorage.write(key: 'hasRegistered', value: 'true');
        
        // 로그인 성공 시 이메일 저장
        await _saveEmail();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 성공')),
        );
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 실패: 이메일 또는 비밀번호를 확인해주세요.')),
        );
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _showLoginForm ? _buildLoginForm() : _buildWelcomeScreen(),
      ),
    );
  }

  // 첫 번째 화면 (환영 화면)
  Widget _buildWelcomeScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // 상단 여백
          const SizedBox(height: 60),
          
          // 이미지 플레이스홀더
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                '로고',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          
          // 중간 여백
          const Spacer(),
          
          // 로그인 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _toggleLoginForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF002B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                '로그인',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
         
          // 하단 여백
          const SizedBox(height: 24),
          
          // 회원가입 링크
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '아직 회원이 아니신가요? ',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/signup'),
                child: const Text(
                  '회원가입',
                  style: TextStyle(
                    color: Color(0xFFFF002B),
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFFFF002B),
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
    );
  }

  // 두 번째 화면 (로그인 폼)
  Widget _buildLoginForm() {
    return Scaffold(
      appBar: CustomAppBar(
        appBarType: AppBarType.backOnly,
        title: const Text(
          '로그인',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        onBackPressed: _goBack,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // 이메일 입력 필드
            const Text(
              '이메일',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: '이메일을 입력해 주세요',
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF002B), width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 비밀번호 입력 필드
            const Text(
              '비밀번호',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: '비밀번호를 입력해 주세요',
                prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF002B), width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
                         // 이메일 저장 및 이메일/비밀번호 찾기 링크
             Row(
               children: [
                 // '이메일 저장' 텍스트와 체크박스를 하나로 묶어 터치 영역을 넓힘
                 GestureDetector(
                   onTap: () async {
                     setState(() {
                       _saveId = !_saveId;
                     });
                     await _saveEmail();
                   },
                   child: Row(
                     mainAxisSize: MainAxisSize.min, // Row가 필요한 만큼만 공간을 차지하도록 설정
                     children: [
                       Checkbox(
                         value: _saveId,
                         onChanged: (value) async {
                           setState(() {
                             _saveId = value ?? false;
                           });
                           await _saveEmail();
                         },
                         activeColor: const Color(0xFFFF002B),
                         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                         visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                       ),
                       // 체크박스와 텍스트 사이의 간격
                       const SizedBox(width: 4),
                       const Text(
                         '이메일 저장',
                         style: TextStyle(
                           fontSize: 14,
                           color: Colors.grey,
                         ),
                       ),
                     ],
                   ),
                 ),
                 const Spacer(),
                 GestureDetector(
                   onTap: () {
                     context.push('/reset-password');
                   },
                   child: const Text(
                     '비밀번호 재설정',
                     style: TextStyle(
                       color: Colors.grey,
                       fontSize: 14,
                     ),
                   ),
                 ),
               ],
             ),
            
            const SizedBox(height: 32),
            
            // 로그인 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF002B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '로그인',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const Spacer(),
            
            // 회원가입 링크
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '아직 회원이 아니신가요? ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/signup'),
                  child: const Text(
                    '회원가입',
                    style: TextStyle(
                      color: Color(0xFFFF002B),
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFFFF002B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
