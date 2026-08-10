import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

// Secure Storage 키를 위한 상수
const String hasRegistered = 'hasRegistered';
const String token = 'token';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  final _storage = const FlutterSecureStorage();

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
    _initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 최소 노출 시간을 보장하면서 인증 상태를 확인하고 화면을 전환합니다.
  Future<void> _initialize() async {
    final List<dynamic> results = await Future.wait([
      _checkAccessAndGetRoute(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    final String route = results[0];

    if (mounted) {
      // --- 수정한 부분: 라우트 상수를 직접 문자열로 사용 ---
      context.go(route);
    }
  }

  /// Secure Storage를 확인하여 다음에 이동할 경로를 반환합니다.
  Future<String> _checkAccessAndGetRoute() async {
    try {
      final tokenValue = await _storage.read(key: token);

      if (tokenValue != null && tokenValue.isNotEmpty) {
        return '/';
      }

      final hasRegisteredValue = await _storage.read(key: hasRegistered);

      if (hasRegisteredValue == 'true') {
        return '/login';
      }

      return '/start';
    } catch (e, stackTrace) {
      developer.log('스플래시 화면 초기화 에러', error: e, stackTrace: stackTrace);
      return '/start';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 300),
              const Text(
                'From',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF767676),
                ),
              ),
              Row(
                mainAxisAlignment:MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/icon.png',
                        fit: BoxFit.fill,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Crewer',
                    style: TextStyle(
                      fontFamily: 'ios',
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111111),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}