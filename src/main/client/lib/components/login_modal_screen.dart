import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginModalScreen extends StatefulWidget {
  @override
  _LoginModalScreenState createState() => _LoginModalScreenState();
}

class _LoginModalScreenState extends State<LoginModalScreen> {

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    setState(() => _loading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      usernameController.text.trim(),
      passwordController.text.trim(),
    );

    const SnackBar(content: Text('여기까지 실행'));

    // 위젯이 아직 화면에 있다면 UI를 업데이트합니다.
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 성공')),
        );
        // 모달을 닫고 홈으로 이동합니다.
        context.pop();
        // context.go('/'); // 홈으로 이동하는 로직은 상태 변화에 따라 자동으로 처리되도록 구성하는 것이 더 좋습니다.
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 실패: 아이디 또는 비밀번호를 확인해주세요.')),
        );
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: FractionallySizedBox(
        heightFactor: 0.6,
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '로그인/회원가입',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9CB4CD),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: '아이디(이메일)',
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: const Color(0xF2E4E7EA),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: const Color(0xF2E4E7EA),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9CB4CD),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _loading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text(
                  '로그인',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // context.pop();                 // 모달 먼저 닫기
                  context.push('/signup');      // 그리고 회원가입 페이지로 이동
                },
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
                            decoration: TextDecoration.underline,
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
      ),
    );
  }
}