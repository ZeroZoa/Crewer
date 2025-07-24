import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/components/login_modal_screen.dart';
import 'package:go_router/go_router.dart';

/// 그룹 피드 수정 화면
class GroupFeedEditScreen extends StatefulWidget {
  final String groupFeedId;
  const GroupFeedEditScreen({Key? key, required this.groupFeedId}) : super(key: key);

  @override
  _GroupFeedEditScreenState createState() => _GroupFeedEditScreenState();
}

class _GroupFeedEditScreenState extends State<GroupFeedEditScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  int _maxParticipants = 2;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetch();
  }

  Future<void> _checkLoginAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLoginModal());
      return;
    }
    try {
      final resp = await http.get(
        Uri.parse('http://localhost:8080/groupfeeds/${widget.groupFeedId}/edit'),
        //Uri.parse('http://10.0.2.2:8080/groupfeeds/${widget.groupFeedId}/edit'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        _titleController.text = data['title'] ?? '';
        _contentController.text = data['content'] ?? '';
        setState(() => _maxParticipants = data['maxParticipants'] ?? 2);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('권한 오류'),
              content: const Text('게시글을 수정할 권한이 없습니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    context.replace('/groupfeeds/${widget.groupFeedId}');
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        });
      }
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginModalScreen(),
    );
  }

  Future<void> _handleUpdate() async {
    if (_submitting) return;
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty ||
        _maxParticipants < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목, 내용, 최대 참가 인원을 입력하세요.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      _showLoginModal();
      setState(() => _submitting = false);
      return;
    }
    try {
      final resp = await http.put(
        Uri.parse('http://localhost:8080/groupfeeds/${widget.groupFeedId}/edit'),
        //Uri.parse('http://10.0.2.2:8080/groupfeeds/${widget.groupFeedId}/edit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'maxParticipants': _maxParticipants,
        }),
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('그룹 피드가 수정되었습니다.')),
        );
        context.replace('/groupfeeds/${widget.groupFeedId}');
      } else {
        final errorText = resp.body;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('수정 실패'),
            content: Text(errorText),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('서버 오류'),
          content: const Text('서버 오류가 발생했습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '그룹 피드 수정',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF9CB4CD), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      labelText: '내용',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                Text(
                  '최대 참가 인원: $_maxParticipants',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
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
                    onPressed: _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9CB4CD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_submitting ? '수정 중...' : '수정 완료'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.replace('/groupfeeds/${widget.groupFeedId}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
