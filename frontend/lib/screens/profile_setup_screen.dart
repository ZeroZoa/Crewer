import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../components/custom_app_bar.dart';
import '../components/profile/profile_avatar_picker.dart';
import 'region_selection_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String? _selectedGender;
  String? _selectedProvinceId;
  String? _selectedProvinceName;
  String? _selectedDistrictName;
  String? _selectedDistrictId;
  List<Map<String, dynamic>> _provinces = [];
  bool _isLoadingProvinces = false;
  bool _isSaving = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _isLoadingProvinces = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/regions/provinces'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _provinces = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      // 시/도 목록 로딩 실패 시 무시 (사용자는 드롭다운이 비어있는 것으로 확인 가능)
    } finally {
      setState(() {
        _isLoadingProvinces = false;
      });
    }
  }

  void _navigateToRegionSelection() {
    if (_selectedProvinceId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegionSelectionScreen(
          provinceId: _selectedProvinceId!,
          provinceName: _selectedProvinceName!,
          onDistrictSelected: (districtName, districtId) {
            setState(() {
              _selectedDistrictName = districtName;
              _selectedDistrictId = districtId;
            });
          },
        ),
      ),
    );
  }

  Future<void> _onComplete() async {
    // 성별이 선택되었는지 확인
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('성별을 선택해주세요')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 토큰 가져오기
      final token = await _storage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다')),
        );
        return;
      }

      // 활동 지역을 백엔드로 저장 (선택된 경우에만)
      if (_selectedDistrictId != null) {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/regions/members/activity-region'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'regionId': _selectedDistrictId,
          }),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            // 성공 시 다음 화면으로 이동
            context.push('/profile-setup/interests');
          } else {
            throw Exception(responseData['message'] ?? '활동 지역 저장에 실패했습니다');
          }
        } else {
          throw Exception('활동 지역 저장에 실패했습니다 (${response.statusCode})');
        }
      } else {
        // 활동 지역이 선택되지 않은 경우에도 다음 화면으로 이동
        context.push('/profile-setup/interests');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        appBarType: AppBarType.backOnly,
        title: const Text(
          '프로필 설정',
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
            const SizedBox(height: 40),
            
            // 프로필 이미지
            Center(
              child: ProfileAvatarPicker(
                avatarUrl: null,
                radius: 60,
                onUploadSuccess: () {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('프로필 이미지가 업로드되었습니다')),
                    );
                  }
                },
                onUploadError: (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  }
                },
              ),
            ),
            
            const SizedBox(height: 40),
            
                // 성별 선택
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
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
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedGender == '남성' ? Color(0xFFFF002B) : Color(0xFFE0E0E0),
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
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedGender == '여성' ? Color(0xFFFF002B) : Color(0xFFE0E0E0),
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
            
            const SizedBox(height: 24),
            
                // 활동 지역 선택
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '활동 지역',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                // 시/도 선택
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isLoadingProvinces
                      ? Row(
                          children: const [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9E9E9E)),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '시/도 목록을 불러오는 중...',
                              style: TextStyle(color: Color(0xFF757575)),
                            ),
                          ],
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedProvinceId,
                            hint: const Text(
                              '시/도를 선택해주세요',
                              style: TextStyle(color: Color(0xFF757575)),
                            ),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF757575),
                            ),
                            items: _provinces.map((province) {
                              return DropdownMenuItem<String>(
                                value: province['regionId'],
                                child: Text(
                                  province['regionName'],
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedProvinceId = value;
                                _selectedProvinceName = _provinces
                                    .firstWhere((p) => p['regionId'] == value)['regionName'];
                                _selectedDistrictName = null; // 시/도 변경 시 상세 지역 초기화
                              });
                            },
                          ),
                        ),
                ),
                
                const SizedBox(height: 12),
                
                // 상세 지역 선택 버튼
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedProvinceId != null 
                        ? _navigateToRegionSelection
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedProvinceId != null 
                          ? Color(0xFFF5F5F5) 
                          : Color(0xFFEEEEEE),
                      foregroundColor: _selectedProvinceId != null 
                          ? Colors.black87 
                          : Color(0xFF757575),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _selectedProvinceId != null 
                            ? "$_selectedProvinceName 상세 지역 선택"
                            : "시/도를 먼저 선택해주세요",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 선택된 상세 지역 표시
                if (_selectedDistrictName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF002B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFFFF002B).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFFFF002B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDistrictName!,
                            style: const TextStyle(
                              color: Color(0xFFFF002B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            const Spacer(),
            
            // 입력완료 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  await _onComplete();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaving ? Color(0xFFE0E0E0) : Color(0xFFFF002B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '저장 중...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        '입력완료',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 58),
          ],
        ),
      ),
    );
  }
}
