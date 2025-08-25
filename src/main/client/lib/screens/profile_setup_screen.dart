import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../components/custom_app_bar.dart';

class ProfileSetupScreen extends StatefulWidget {
  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _locationController = TextEditingController();
  String? _selectedGender; // 성별 선택 상태
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // 사용자 데이터 로드 (필요시 구현)
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _onComplete() async {
    // 성별이 선택되었는지 확인
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('성별을 선택해주세요')),
      );
      return;
    }

    // 활동 지역이 입력되었는지 확인
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('활동 지역을 입력해주세요')),
      );
      return;
    }

    try {
      // 토큰 가져오기
      final token = await _storage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다')),
        );
        return;
      }

      // 성별과 활동 지역을 백엔드로 저장 (필요시 구현)
      // TODO: 백엔드 API 구현 후 저장 로직 추가

      // 성공 시 다음 화면으로 이동
      context.push('/profile-setup/interests');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        appBarType: AppBarType.backOnly,
        title: Text(
          '프로필 설정',
          style: TextStyle(
            fontSize: 18,
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
            const SizedBox(height: 40),
            
            // 프로필 이미지 영역
            Center(
              child: Stack(
                children: [
                  // 프로필 이미지 원형 컨테이너
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF5F5F5),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  // 편집 아이콘
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF002B),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
                         const SizedBox(height: 40),
            
                         // 성별 선택 버튼
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   '성별',
                   style: TextStyle(
                     fontSize: 14,
                     color: Colors.black87,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
                 const SizedBox(height: 8),
                 Row(
                   children: [
                     // 남성 버튼
                     Expanded(
                       child: GestureDetector(
                         onTap: () {
                           setState(() {
                             _selectedGender = '남성';
                           });
                         },
                         child: Container(
                           height: 48,
                           decoration: BoxDecoration(
                             color: _selectedGender == '남성' ? Color(0xFFFF002B) : Color(0xFFF5F5F5),
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(
                               color: _selectedGender == '남성' ? Color(0xFFFF002B) : Colors.grey.shade300,
                               width: 1,
                             ),
                           ),
                           child: Center(
                             child: Text(
                               '남성',
                               style: TextStyle(
                                 color: _selectedGender == '남성' ? Colors.white : Colors.black87,
                                 fontSize: 16,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ),
                         ),
                       ),
                     ),
                     
                     const SizedBox(width: 12),
                     
                     // 여성 버튼
                     Expanded(
                       child: GestureDetector(
                         onTap: () {
                           setState(() {
                             _selectedGender = '여성';
                           });
                         },
                         child: Container(
                           height: 48,
                           decoration: BoxDecoration(
                             color: _selectedGender == '여성' ? Color(0xFFFF002B) : Color(0xFFF5F5F5),
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(
                               color: _selectedGender == '여성' ? Color(0xFFFF002B) : Colors.grey.shade300,
                               width: 1,
                             ),
                           ),
                           child: Center(
                             child: Text(
                               '여성',
                               style: TextStyle(
                                 color: _selectedGender == '여성' ? Colors.white : Colors.black87,
                                 fontSize: 16,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ),
                         ),
                       ),
                     ),
                   ],
                 ),
               ],
             ),
            
            const SizedBox(height: 16),
            
            // 활동 지역 입력 필드
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: '활동 지역을 입력해주세요',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  border: InputBorder.none,
                ),
              ),
            ),
            
            const Spacer(),
            
                               // 입력완료 버튼
                   SizedBox(
                     width: double.infinity,
                     height: 56,
                     child: ElevatedButton(
                       onPressed: () async {
                         await _onComplete();
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Color(0xFFFF002B),
                         foregroundColor: Colors.white,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(16),
                         ),
                         elevation: 0,
                       ),
                       child: Text(
                         '입력완료',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                     ),
                   ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
