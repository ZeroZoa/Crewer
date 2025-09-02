import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../components/custom_app_bar.dart';

class ProfileInterestsScreen extends StatefulWidget {
  @override
  _ProfileInterestsScreenState createState() => _ProfileInterestsScreenState();
}

class _ProfileInterestsScreenState extends State<ProfileInterestsScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Set<String> selectedInterests = Set<String>();
  bool _isLoading = false;

  // 관심사 목록 (실제 앱에서는 서버에서 가져올 수 있음)
  final List<String> allInterests = [
    '러닝', '독서', '음악', '여행', '사진',
    '요리', '운동', '영화', '게임', '미술',
    '등산', '수영', '자전거', '테니스', '골프',
    '피아노', '기타', '춤', '요가', '필라테스',
    '명상', '캠핑', '낚시', '스키', '스노보드',
    '축구', '농구', '야구', '배구', '탁구'
  ];

  @override
  void initState() {
    super.initState();
    // 기본적으로 러닝 선택
    selectedInterests.add('러닝');
  }

  void _onSelectLater() {
    // 다음에 선택하기 - 메인 화면으로 이동
    context.go('/');
  }

  Future<void> _onComplete() async {
    if (selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최소 하나의 관심사를 선택해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 관심사 저장 API 호출
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}/me/interests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(selectedInterests.toList()),
      );

      if (response.statusCode == 200) {
        // 성공 시 완료 화면으로 이동
        context.push('/profile-setup/complete');
      } else {
        throw Exception('관심사 저장에 실패했습니다');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        appBarType: AppBarType.backOnly,
        title: Text(
          '관심사 설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        onBackPressed: () => context.pop(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 텍스트
            Text(
              '고객님이 평소 좋아하는 관심사 키워드를 선택하세요\n선택하신 키워드는 언제든 바꿀 수 있습니다.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 관심사 선택 영역
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: allInterests.map((interest) {
                    final isSelected = selectedInterests.contains(interest);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedInterests.remove(interest);
                          } else {
                            selectedInterests.add(interest);
                          }
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Color(0xFFFF002B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Color(0xFFFF002B) : Color(0xFFFF002B),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Text(
                              interest,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Color(0xFFFF002B),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                                                         // 선택된 관심사에 대한 번호 표시 제거
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 하단 버튼들
            Row(
              children: [
                // 다음에 선택하기 버튼
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onSelectLater,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '다음에 선택하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 선택완료 버튼
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF002B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              '선택완료',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
