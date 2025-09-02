import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../components/custom_app_bar.dart';
import 'region_selection_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String? _selectedGender; // 성별 선택 상태
  String? _selectedProvinceId; // 선택된 시/도 ID
  String? _selectedProvinceName; // 선택된 시/도 이름
  String? _selectedDistrictName; // 선택된 행정동 이름
  List<Map<String, dynamic>> _provinces = []; // 시/도 목록
  bool _isLoadingProvinces = false; // 시/도 목록 로딩 상태
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProvinces();
  }

  Future<void> _loadUserData() async {
    // 사용자 데이터 로드 (필요시 구현)
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
      print('시/도 목록 로드 오류: $e');
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
          onDistrictSelected: (districtName) {
            setState(() {
              _selectedDistrictName = districtName;
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

    // 시/도가 선택되었는지 확인
    if (_selectedProvinceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시/도를 선택해주세요')),
      );
      return;
    }

    // 행정동이 선택되었는지 확인
    if (_selectedDistrictName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상세 지역을 선택해주세요')),
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
            
            const SizedBox(height: 24),
            
            // 활동 지역 선택
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoadingProvinces
                      ? Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '시/도 목록을 불러오는 중...',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedProvinceId,
                            hint: Text(
                              '시/도를 선택해주세요',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            isExpanded: true,
                            items: _provinces.map((province) {
                              return DropdownMenuItem<String>(
                                value: province['regionId'],
                                child: Text(province['regionName']),
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
                          : Colors.grey.shade200,
                      foregroundColor: _selectedProvinceId != null 
                          ? Colors.black87 
                          : Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
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
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF002B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFFF002B).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFFFF002B),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDistrictName!,
                            style: TextStyle(
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
            
            const SizedBox(height: 58),
          ],
        ),
      ),
    );
  }
}
