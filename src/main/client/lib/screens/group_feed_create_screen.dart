import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';
import 'package:intl/intl.dart';
import '../components/custom_app_bar.dart';
import '../config/api_config.dart';

/// 그룹 피드 작성 화면
class GroupFeedCreateScreen extends StatefulWidget {
  const GroupFeedCreateScreen({Key? key}) : super(key: key);

  @override
  _GroupFeedCreateScreenState createState() => _GroupFeedCreateScreenState();
}

class _GroupFeedCreateScreenState extends State<GroupFeedCreateScreen> {
  bool _isSubmitting = false;
  int _maxParticipants = 2;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _meetingPlaceController = TextEditingController();
  DateTime? _deadline;

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      // 로그인 모달 표시
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => LoginModalScreen(),
      );

      // 모달 닫힌 뒤에도 여전히 비로그인 상태라면 이전 화면으로 돌아감
      final newToken = await _storage.read(key: _tokenKey);

      if (newToken == null) {
        context.pop();
      }
    }
  }

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginModalScreen(),
    );
  }

  Future<void> _selectDeadline(BuildContext context) async {
    // 날짜 선택
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate == null) return; // 날짜 선택 취소

    // 시간 선택
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );

    if (pickedTime == null) return; // 시간 선택 취소

    // 선택된 날짜와 시간을 합쳐서 상태 업데이트
    setState(() {
      _deadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      _showLoginModal();
      setState(() => _isSubmitting = false);
      return;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedCreate()}');
    final body = json.encode({
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'maxParticipants': _maxParticipants,
      'meetingPlace': _meetingPlaceController.text.trim(),
      'deadline': _deadline?.toUtc().toIso8601String(),
    });

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('그룹 피드 작성이 완료되었습니다!')),
          );
          context.replace('/');
        });
      } else {
        final errorText = resp.body;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('작성 실패'),
              content: Text(errorText),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        });
      }
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('서버 오류'),
            content: const Text('서버 오류가 발생했습니다.'),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      });
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarType: AppBarType.close,
        title: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 0, top: 4),
          child: Text(
            '그룹피드 게시글',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        ),
        actions: [],
      ),
        body: SingleChildScrollView( // 키보드가 올라올 때 UI가 밀리는 것을 방지
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '제목을 입력해주세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF9CB4CD), width: 2),
                      ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 200,
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: '내용을 입력해주세요',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF9CB4CD), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _meetingPlaceController,
                    decoration: InputDecoration(
                      labelText: '모임 장소를 입력해주세요 (선택)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF9CB4CD), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 마감 시간 선택 UI
                  OutlinedButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text(
                      _deadline == null
                          ? '마감 시간 설정 (선택)'
                      // intl 패키지를 사용하여 날짜 포맷 지정
                          : DateFormat('yyyy년 MM월 dd일 HH:mm').format(_deadline!),
                    ),
                    onPressed: () => _selectDeadline(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('최대 참가 인원: $_maxParticipants', style: const TextStyle(fontSize: 16)),
                  Slider(
                    value: _maxParticipants.toDouble(),
                    min: 2,
                    max: 10,
                    divisions: 8,
                    label: '$_maxParticipants',
                    onChanged: (v) => setState(() => _maxParticipants = v.toInt()),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9CB4CD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(_isSubmitting ? '작성 중...' : '작성 완료'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
