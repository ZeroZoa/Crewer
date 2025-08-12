import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

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
                        // 페이지 변경 시 인디케이터 갱신
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        children: const [
                          // 1 페이지
                          _OnboardPage(
                            title: '안내 1',
                            description: '1번 화면 설명 텍스트 (이미지 예정)',
                          ),
                          // 2 페이지
                          _OnboardPage(
                            title: '안내 2',
                            description: '2번 화면 설명 텍스트 (이미지 예정)',
                          ),
                          // 3 페이지
                          _OnboardPage(
                            title: '안내 3',
                            description: '3번 화면 설명 텍스트 (이미지 예정)',
                          ),
                          //_LoginPage()
                        ],
                      ),
                    ),

                    // 현재 페이지를 보여주는 동그라미 인디케이터
                    const SizedBox(height: 12),
                    _PageDots(
                      length: 4,
                      currentIndex: _currentPage,
                      activeColor: Colors.black,
                      inActiveColor: Colors.grey,
                    ),
                    const SizedBox(height: 16),

                    // 로그인 페이지는 PageView의 4번째 페이지에 오버레이처럼 배치하지 않고
                    // 위의 PageView children에 직접 넣을 수도 있음.
                    // 여기서는 한 파일 가독성을 위해 아래에서 조건부로 렌더링하지 않고,
                    // 위 children에 포함시키는 형태로 변경하는 게 더 명확하므로
                    // 위 PageView의 children을 const가 아닌 동적 생성으로 교체.
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

  const _OnboardPage({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 이미지가 들어갈 자리
          // 실제 런타임에서는 Image.asset / Image.network 등으로 교체하면 됨
          Container(
            width: isWide ? 280 : 220,
            height: isWide ? 280 : 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: const FlutterLogo(size: 96),
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
          width: isActive ? 10 : 8,  // 활성 시 조금 더 크게
          height: isActive ? 10 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : inactive,
          ),
        );
      }),
    );
  }
}










//아래는 필요없음


// /// 마지막 페이지의 로그인 폼
// /// - 아이디/비밀번호 입력
// /// - 로그인 버튼
// /// - 회원가입 버튼(로그인 버튼 아래)
// class _LoginPage extends StatelessWidget {
//   final GlobalKey<FormState> formKey;
//   final TextEditingController idController;
//   final TextEditingController pwController;
//   final bool obscure; // 비밀번호 표시/숨김 상태
//   final VoidCallback onToggleObscure; // 눈 아이콘 클릭 시 토글
//   final VoidCallback onLoginPressed; // 로그인 버튼 핸들러
//   final VoidCallback onSignupPressed; // 회원가입 버튼 핸들러
//
//   const _LoginPage({
//     required this.formKey,
//     required this.idController,
//     required this.pwController,
//     required this.obscure,
//     required this.onToggleObscure,
//     required this.onLoginPressed,
//     required this.onSignupPressed,
//   });
//
//   static const Color mainColor = Color(0xFF9CB4CD);
//
//   @override
//   Widget build(BuildContext context) {
//     final maxW = MediaQuery.of(context).size.width;
//     final isWide = maxW > 600;
//     final contentWidth = isWide ? 420.0 : double.infinity;
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//       child: Center(
//         child: ConstrainedBox(
//           constraints: BoxConstraints(maxWidth: contentWidth),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // 헤더 텍스트
//               const SizedBox(height: 16),
//               Text(
//                 '로그인',
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 '계정으로 로그인해 주세요.',
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodyMedium
//                     ?.copyWith(color: Colors.grey.shade700),
//               ),
//               const SizedBox(height: 24),
//
//               // 폼 영역
//               Form(
//                 key: formKey,
//                 child: Column(
//                   children: [
//                     // 아이디 입력
//                     TextFormField(
//                       controller: idController,
//                       textInputAction: TextInputAction.next,
//                       decoration: const InputDecoration(
//                         labelText: '아이디',
//                         hintText: '아이디를 입력하세요',
//                         border: OutlineInputBorder(),
//                       ),
//                       validator: (v) {
//                         if (v == null || v.trim().isEmpty) {
//                           return '아이디를 입력해주세요';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//
//                     // 비밀번호 입력
//                     TextFormField(
//                       controller: pwController,
//                       obscureText: obscure,
//                       decoration: InputDecoration(
//                         labelText: '비밀번호',
//                         hintText: '비밀번호를 입력하세요',
//                         border: const OutlineInputBorder(),
//                         // 눈 아이콘으로 표시/숨김 토글
//                         suffixIcon: IconButton(
//                           onPressed: onToggleObscure,
//                           icon: Icon(obscure
//                               ? Icons.visibility_off
//                               : Icons.visibility),
//                           tooltip: obscure ? '표시' : '숨김',
//                         ),
//                       ),
//                       validator: (v) {
//                         if (v == null || v.isEmpty) {
//                           return '비밀번호를 입력해주세요';
//                         }
//                         if (v.length < 6) {
//                           return '비밀번호는 6자 이상이어야 합니다';
//                         }
//                         return null;
//                       },
//                       // 엔터 입력 시 로그인 시도
//                       onFieldSubmitted: (_) => onLoginPressed(),
//                     ),
//                     const SizedBox(height: 20),
//
//                     // 로그인 버튼
//                     SizedBox(
//                       height: 48,
//                       child: ElevatedButton(
//                         onPressed: onLoginPressed,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: mainColor,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text(
//                           '로그인',
//                           style: TextStyle(fontWeight: FontWeight.w600),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 12),
//
//                     // 회원가입 버튼 (아웃라인)
//                     SizedBox(
//                       height: 44,
//                       child: OutlinedButton(
//                         onPressed: onSignupPressed,
//                         style: OutlinedButton.styleFrom(
//                           side: const BorderSide(color: mainColor),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text(
//                           '회원가입',
//                           style: TextStyle(fontWeight: FontWeight.w600),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }