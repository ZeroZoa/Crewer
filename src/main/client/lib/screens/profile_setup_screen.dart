import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
  String? _selectedDistrictId; // 선택된 행정동 ID
  List<Map<String, dynamic>> _provinces = []; // 시/도 목록
  bool _isLoadingProvinces = false; // 시/도 목록 로딩 상태
  bool _isSaving = false; // 저장 중 상태
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // 프로필 이미지 관련
  File? _selectedImage;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProvinces();
  }

  Future<void> _loadUserData() async {
    // 사용자 데이터 로드 (필요시 구현)
  }

  // 이미지 선택 메서드
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        
        // 이미지 업로드
        await _uploadProfileImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 프로필 이미지 업로드 메서드
  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다')),
        );
        return;
      }

      // MultipartFile 생성
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/profile/me/avatar'),
      );

      // 헤더 설정
      request.headers['Authorization'] = 'Bearer $token';

      // 파일 추가
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        ),
      );

      // 요청 전송
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 이미지가 업로드되었습니다')),
        );
      } else {
        final responseBody = await response.stream.bytesToString();
        print('프로필 이미지 업로드 실패: ${response.statusCode} - $responseBody');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 이미지 업로드에 실패했습니다')),
        );
      }
    } catch (e) {
      print('프로필 이미지 업로드 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 이미지 업로드 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
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

      // 활동 지역을 백엔드로 저장
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
              child: GestureDetector(
                onTap: _isUploadingImage ? null : _pickImage,
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
                      child: _selectedImage != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedImage!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey.shade600,
                            ),
                    ),
                    
                    // 편집 아이콘 (업로드 중일 때는 로딩 표시)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isUploadingImage ? Colors.grey : Color(0xFFFF002B),
                        ),
                        child: _isUploadingImage
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ],
                ),
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
                            borderRadius: BorderRadius.circular(16),
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
                            borderRadius: BorderRadius.circular(16),
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
                    borderRadius: BorderRadius.circular(16),
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
                        borderRadius: BorderRadius.circular(16),
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
                      borderRadius: BorderRadius.circular(16),
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
                onPressed: _isSaving ? null : () async {
                  await _onComplete();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaving ? Colors.grey.shade300 : Color(0xFFFF002B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                    : Text(
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
