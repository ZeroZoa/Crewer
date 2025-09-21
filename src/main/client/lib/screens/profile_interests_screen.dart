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
  bool _isLoadingCategories = true;
  Map<String, List<String>> interestCategories = {};

  @override
  void initState() {
    super.initState();
    _loadInterestCategories();
  }

  Future<void> _loadInterestCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getInterestCategories()}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          interestCategories = data.map((key, value) => MapEntry(key, List<String>.from(value)));
          _isLoadingCategories = false;
          // 기본적으로 가벼운 조깅 선택
          if (interestCategories.isNotEmpty) {
            selectedInterests.add('가벼운 조깅');
          }
        });
      } else {
        throw Exception('관심사 카테고리 로딩 실패');
      }
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('관심사 카테고리를 불러오는데 실패했습니다: $e')),
      );
    }
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
              '어떤 러닝 스타일과 활동을 선호하시나요?\n선택하신 관심사는 언제든 바꿀 수 있습니다.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 관심사 선택 영역
            Expanded(
              child: _isLoadingCategories
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: interestCategories.entries.map((category) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 카테고리 제목
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  category.key,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF002B),
                                  ),
                                ),
                              ),
                              
                              // 카테고리 내 관심사들
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: category.value.map((interest) {
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
                                      child: Text(
                                        interest,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Color(0xFFFF002B),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              
                              const SizedBox(height: 32),
                            ],
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
