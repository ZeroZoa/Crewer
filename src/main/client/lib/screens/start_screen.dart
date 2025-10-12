import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class StartScreen extends StatefulWidget{

  @override
  _StartScreenState createState() => _StartScreenState();  // 상태 관리 객체를 생성
}

class _StartScreenState extends State<StartScreen>{
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 온보딩 페이지
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const PageScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: const [
                  _OnboardPage(
                    title: '크루원들을 모집해보세요!',
                    description: '그룹피드에서 모집인원과 장소를 선택해 크루원을 모집할 수 있어요.',
                    imagePath: 'assets/images/notice.png',
                  ),
                  _OnboardPage(
                    title: '운동기록을 남겨보세요!',
                    description: '나의 운동기록을 남기고 자신의 기록을 확인할 수 있어요.',
                    imagePath: 'assets/images/calendar.png',
                  ),
                  _OnboardPage(
                    title: '피드로 일상을 공유해보세요!',
                    description: '피드에서 사람들과 일상을 이야기하며 소통할 수 있어요.',
                    imagePath: 'assets/images/chat.png',
                  ),
                ],
              ),
            ),

            // 페이지 인디케이터
            const SizedBox(height: 12),
            _PageDots(
              length: 3,
              currentIndex: _currentPage,
              activeColor: const Color(0xFFFF002B),
              inActiveColor: Colors.grey,
            ),
            const SizedBox(height: 16),

            // 다음/시작하기 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < 2) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      context.go('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFFF002B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage < 2 ? '다음' : '시작하기',
                    style: const TextStyle(
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
  }

}

/// 온보딩 단일 페이지 위젯
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
            borderRadius: BorderRadius.circular(16),
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




/// 하단 페이지 인디케이터
class _PageDots extends StatelessWidget {
  final int length;
  final int currentIndex;
  final Color activeColor;
  final Color inActiveColor;

  const _PageDots({
    required this.length,
    required this.currentIndex,
    required this.activeColor,
    required this.inActiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isActive ? activeColor : Colors.grey.shade400,
          ),
        );
      }),
    );
  }
}