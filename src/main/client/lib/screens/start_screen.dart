import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';


class StartScreen extends StatefulWidget{

  @override
  _StartScreenState createState() => _StartScreenState();  // 상태 관리 객체를 생성
}

class _StartScreenState extends State<StartScreen>{
  final TextEditingController _usernameController = TextEditingController();  //아이디 입력
  final TextEditingController _passwordController = TextEditingController();  //비밀번호 입력

  final PageController _pageController = PageController();  // 페이지 스와이프를 제어하는 컨트롤러

  int _currentPage = 0;  // 현재 페이지 인덱스 (0~3)
  bool _loading = false;  // 로딩 유무 확인
  bool _obscure = true;  // 비밀번호 표시/숨김


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    //스크린 사이즈를 기준으로
    final screenSize  = MediaQuery.of(context).size;

    //본문
    return Scaffold(
      // SafeArea로 노치/시스템 영역 피하기
      body: SafeArea(
        // LayoutBuilder로 가용 너비에 따라 반응형 폭 조절
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(),
                child: Column(
                  children: [
                    // 콘텐츠 영역: 온보딩 3장 + 로그인 1장
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        // 스와이프 활성화
                        physics: const PageScrollPhysics(),
                        // 페이지 변경 시 인디케이터 갱신
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        children: const [
                          // 1 페이지
                          _OnboardPage(
                            title: '크루원들을 모집해보세요',
                            description: '그룹피드에서 모집인원과 장소를 선택해 크루원을 모집합니다.',
                            imagePath: 'assets/images/notice.png',
                          ),
                          // 2 페이지
                          _OnboardPage(
                            title: '운동기록을 남겨보세요',
                            description: '나의 운동기록을 남기고 자신의 기록을 확인할 수 있습니다.',
                            imagePath: 'assets/images/calendar.png',
                          ),
                          // 3 페이지
                          _OnboardPage(
                            title: '피드로 일상을 공유해보세요',
                            description: '피드에서 사람들과 일상을 이야기하며 소통할 수 있습니다.',
                            imagePath: 'assets/images/chat.png',
                          ),
                          //_LoginPage()
                        ],
                      ),
                    ),

                    // 현재 페이지를 보여주는 인디케이터
                    const SizedBox(height: 12),
                    _PageDots(
                      length: 3,
                      currentIndex: _currentPage,
                      activeColor: Color(0xFFFF002B),
                      inActiveColor: Colors.grey,
                    ),
                    const SizedBox(height: 16),

                    // 다음 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < 2) {
                              // 다음 페이지로 이동
                              _pageController.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              // 마지막 페이지에서 로그인 화면으로 이동
                              context.go('/login');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Color(0xFFFF002B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _currentPage < 2 ? '다음' : '시작하기',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}

//  온보딩 단일 페이지 위젯
//  이미지 영역
//  타이틀/설명 텍스트
class _OnboardPage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;

  const _OnboardPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 온보딩 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: isWide ? 280 : 220,
              height: isWide ? 280 : 220,
            ),
          ),
          const SizedBox(height: 24),

          // 타이틀
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // 설명 텍스트
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}




// 하단 페이지 인디케이터(작은 원들)
class _PageDots extends StatelessWidget {
  final int length;  // - length: 전체 페이지 수
  final int currentIndex;  // - currentIndex: 현재 페이지 인덱스
  final Color activeColor;  // - activeColor: 활성 점 색상
  final Color inActiveColor;  // - inActiveColor: 비활성 점 색상

  const _PageDots({
    required this.length,
    required this.currentIndex,
    required this.activeColor,
    required this.inActiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = Colors.grey.shade400; // 비활성 점 색상

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 24 : 8,  // 활성 시 가로로 길게
          height: isActive ? 8 : 8,  // 활성 시 높이는 그대로
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16), // 모서리를 둥글게
            color: isActive ? activeColor : inactive,
          ),
        );
      }),
    );
  }
}