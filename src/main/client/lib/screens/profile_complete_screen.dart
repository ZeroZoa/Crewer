import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/custom_app_bar.dart';

class ProfileCompleteScreen extends StatefulWidget {
  @override
  _ProfileCompleteScreenState createState() => _ProfileCompleteScreenState();
}

class _ProfileCompleteScreenState extends State<ProfileCompleteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        appBarType: AppBarType.backOnly,
        title: const Text(
          '설정 완료',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        onBackPressed: () => context.pop(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 60),
            
            // 완료 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/check.jpg',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 주요 완료 메시지
            const Text(
              '설정이 완료되었습니다',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // 보조 메시지
            const Text(
              '이제 함께 달릴 크루를 찾아보세요!',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF757575),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const Spacer(),
            
            // 같이 달리러가기 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // 메인 화면으로 이동
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF002B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '같이 달리러가기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
