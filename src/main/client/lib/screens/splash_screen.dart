import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
    
    // 2초 후 접속 기록 확인 및 화면 이동
    Future.delayed(const Duration(seconds: 2), () {
      _checkFirstAccess();
    });
  }

  Future<void> _checkFirstAccess() async {
    final FlutterSecureStorage _storage = const FlutterSecureStorage();
    final String _registrationKey = 'hasRegistered';
    
    try {
      final hasRegistered = await _storage.read(key: _registrationKey);
      
      if (hasRegistered == 'true') {
        // 기존 사용자: 로그인 화면으로 이동
        if (mounted) {
          context.go('/login');
        }
      } else {
        // 첫 접속: 온보딩 화면으로 이동
        if (mounted) {
          context.go('/start');
        }
      }
    } catch (e) {
      // 에러 발생 시 온보딩 화면으로 이동
      if (mounted) {
        context.go('/start');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
             body: Center(
         child: FadeTransition(
           opacity: _fadeAnimation,
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                                         // 앱 로고
                     Container(
                       width: 120,
                       height: 120,
                       decoration: BoxDecoration(
                         color: Color(0xFFFF002B),
                         borderRadius: BorderRadius.circular(20),
                         boxShadow: [
                           BoxShadow(
                             color: Color(0xFFFF002B).withOpacity(0.3),
                             blurRadius: 20,
                             offset: const Offset(0, 10),
                           ),
                         ],
                       ),
                       child: const Icon(
                         Icons.directions_run,
                         size: 60,
                         color: Colors.white,
                       ),
                     ),
                     const SizedBox(height: 24),
                     
                     // 앱 이름
                     const Text(
                       'Crewer',
                       style: TextStyle(
                         fontSize: 32,
                         fontWeight: FontWeight.bold,
                         color: Color(0xFFFF002B),
                       ),
                     ),
                    const SizedBox(height: 8),
                    
                    // 부제목
                    const Text(
                      '크루원들과 함께 달려보세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                                         ),
                   ],
                 ),
               ),
             ),
    );
  }
}
