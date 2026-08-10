import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart';

/// 프로필 이미지 선택 및 업로드 위젯
/// 
/// 사용처: MyProfileScreen, ProfileSetupScreen
/// 
/// 사용 예시:
/// ```dart
/// ProfileAvatarPicker(
///   avatarUrl: member.avatarUrl,
///   radius: 40,
///   onUploadSuccess: () {
///     // 프로필 새로고침 로직
///     setState(() => _profileFuture = fetchProfile());
///   },
///   onUploadError: (error) {
///     // 에러 처리
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('업로드 실패: $error')),
///     );
///   },
/// )
/// ```
class ProfileAvatarPicker extends StatefulWidget {
  /// 현재 프로필 이미지 URL (없으면 null)
  final String? avatarUrl;
  
  /// CircleAvatar의 반지름 (기본값: 40)
  final double radius;
  
  /// 업로드 성공 시 콜백
  final VoidCallback? onUploadSuccess;
  
  /// 업로드 실패 시 콜백
  final Function(String error)? onUploadError;
  
  /// 편집 아이콘 크기 (기본값: 프로필 크기에 따라 자동)
  final double? editIconSize;

  const ProfileAvatarPicker({
    Key? key,
    this.avatarUrl,
    this.radius = 40.0,
    this.onUploadSuccess,
    this.onUploadError,
    this.editIconSize,
  }) : super(key: key);

  @override
  State<ProfileAvatarPicker> createState() => _ProfileAvatarPickerState();
}

class _ProfileAvatarPickerState extends State<ProfileAvatarPicker> {
  File? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// 이미지 선택
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
        
        // 이미지 선택 즉시 업로드
        await _uploadProfileImage();
      }
    } catch (e) {
      if (widget.onUploadError != null) {
        widget.onUploadError!('이미지 선택 중 오류가 발생했습니다: $e');
      }
    }
  }

  /// 프로필 이미지 업로드
  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final token = await _storage.read(key: 'token');
      
      if (token == null) {
        if (widget.onUploadError != null) {
          widget.onUploadError!('로그인이 필요합니다');
        }
        return;
      }

      final uploadUrl = '${ApiConfig.baseUrl}${ApiConfig.updateProfileAvatar()}';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(uploadUrl),
      );

      request.headers['Authorization'] = 'Bearer $token';
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        // 업로드 성공
        if (widget.onUploadSuccess != null) {
          widget.onUploadSuccess!();
        }
      } else {
        if (widget.onUploadError != null) {
          widget.onUploadError!('프로필 이미지 업로드에 실패했습니다 (${response.statusCode})');
        }
      }
    } catch (e) {
      if (widget.onUploadError != null) {
        widget.onUploadError!('프로필 이미지 업로드 중 오류가 발생했습니다: $e');
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 편집 아이콘 크기 자동 계산 (프로필 크기의 30%)
    final double editSize = widget.editIconSize ?? (widget.radius * 0.6);
    final double editIconSize = editSize * 0.5;

    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: Stack(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: Colors.grey[300],
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (widget.avatarUrl != null
                    ? NetworkImage(
                        widget.avatarUrl!.startsWith('http')
                            ? widget.avatarUrl!
                            : '${ApiConfig.baseUrl}${widget.avatarUrl!}',
                      )
                    : null) as ImageProvider?,
            child: widget.avatarUrl == null && _selectedImage == null
                ? Icon(
                    Icons.person,
                    size: widget.radius,
                    color: Colors.grey[600],
                  )
                : null,
          ),
          
          // 편집 아이콘 (우측 하단)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: editSize,
              height: editSize,
              decoration: BoxDecoration(
                color: _isUploading ? Colors.grey : const Color(0xFFFF002B),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _isUploading
                  ? Padding(
                      padding: EdgeInsets.all(editSize * 0.25),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      widget.radius > 60 ? Icons.edit : Icons.camera_alt,
                      size: editIconSize,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

