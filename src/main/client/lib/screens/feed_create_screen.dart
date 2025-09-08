import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';
import '../components/custom_app_bar.dart';
import '../config/api_config.dart';

/// 피드 작성 화면
class FeedCreateScreen extends StatefulWidget {
  const FeedCreateScreen({Key? key}) : super(key: key);

  @override
  _FeedCreateScreenState createState() => _FeedCreateScreenState();
}

class _FeedCreateScreenState extends State<FeedCreateScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isSubmitting = false;
  bool _isfilled = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();

    _titleController.addListener(_checkFields);
    _contentController.addListener(_checkFields);
    _checkLogin();
  }

  @override
  void dispose(){
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _checkLogin() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginModal();
      });
    }
  }

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginModalScreen(),
    );
  }
   
  void _checkFields(){   
    if(_titleController.text.trim().isNotEmpty && _contentController.text.trim().isNotEmpty){
      setState(() {
      _isfilled = true;
    });
    }else{
       setState(() {
      _isfilled = false;
    });
    } 
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

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getFeedCreate()}');
    final body = json.encode({
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('피드 작성이 완료되었습니다!')),
          );
          setState(() {
            _isSubmitting = true;
          });
          // context.replace('/');
        });
      } else {
        final errorText = response.body;
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
    if(_isSubmitting){
      return Scaffold(
        appBar: CustomAppBar(
        appBarType: AppBarType.close,
        title: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 0, top: 4),
          child: Text(
            '게시글 작성 완료',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        ),
      ),
      backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            children: [
              Container(  //이미지 넣을 곳
                width: 130,
                height: 130,
                color: Colors.grey.shade200,
              ),
              Text(
                "작성이 완료되었습니다",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold),),
              Text("data"),
              Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (){},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF002B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                            "게시글 보러가기",
                            style: TextStyle(fontSize: 16,)
                        ),
                      ),
                    ),
                  ),
            ],
          )
          ),
        );
    }  

    return Scaffold(
      appBar: CustomAppBar(
        appBarType: AppBarType.close,
        title: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 0, top: 4),
          child: Text(
            '피드 게시글',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => {},
            child: Text("임시저장"),
            style: TextButton.styleFrom(foregroundColor: Color(0xFFBDBDBD)),
            )
          ],
      ),
      backgroundColor: Color(0xFFFAFAFA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '제목을 입력해주세요.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF767676), width: 2),

                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFF767676)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: '내용을 입력해주세요.',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF767676), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isfilled ? Color(0xFFFF002B):const Color(0xFFBDBDBD),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                            _isSubmitting ? '작성 중...' : '작성 완료',
                            style: TextStyle(fontSize: 16,)
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );  
    
  }

}
