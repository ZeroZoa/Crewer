import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http; // HTTP 요청
import 'dart:convert'; // JSON 변환
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart'; // 로그인 모달
import '../components/custom_app_bar.dart';
import '../config/api_config.dart';

/// 피드 수정 화면
class FeedEditScreen extends StatefulWidget {
  final String feedId;
  const FeedEditScreen({Key? key, required this.feedId}) : super(key: key);

  @override
  _FeedEditScreenState createState() => _FeedEditScreenState();
}

class _FeedEditScreenState extends State<FeedEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _loading = true;
  bool _isSubmitting = false;
  bool _isfilled = false;
  bool _isEditComplete = false;
  late var _editFeedId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();

    _titleController.addListener(_checkFields);
    _contentController.addListener(_checkFields);
    _checkLoginAndFetch();
  }

  Future<void> _checkLoginAndFetch() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLoginModal());
      return;
    }
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getFeedEdit(widget.feedId)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        _titleController.text = data['title'] ?? '';
        _contentController.text = data['content'] ?? '';
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
                    context.pop();
                    context.push('/feeds/${widget.feedId}');
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        });
      }
    } catch (_) {
      // 에러 시 상세 페이지로 복귀
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.push('/feeds/${widget.feedId}');
      });
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

  Future<void> _handleUpdate() async {
    if (_isSubmitting) return;
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력하세요.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      _showLoginModal();
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final resp = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getFeedEdit(widget.feedId)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
        }),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final editFeedId = data['id'];
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 수정되었습니다.')),
        );
        setState(() {
            _editFeedId = editFeedId;
            _isEditComplete = true;
          });


      } else {
        final errorText = resp.body;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('수정 실패'),
            content: Text(errorText),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
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
              onPressed: () => context.pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
     if(_isEditComplete){
      return Scaffold(
        appBar: CustomAppBar(
        appBarType: AppBarType.close,
        title: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 0, top: 4),
          child: Text(
            '게시글 수정 완료',
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,                
                child: Image.asset('assets/images/check.jpg')),              
              SizedBox(height: 30,),
              Text(
                "수정이 완료되었습니다",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold),),
            ],
          )
          ),
          bottomNavigationBar:  SafeArea(                                    
        child: Container(
          height: 100,
          decoration: BoxDecoration( color: Colors.white),                                      
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
          child:  SizedBox(
            height: 20,
            child: ElevatedButton(
              onPressed:() {
                final route = '/feeds/${_editFeedId}';
                context.replace(route);
              },
              style: ElevatedButton.styleFrom(                
                backgroundColor: Color(0xFFFF002B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                  '게시글 보러가기',
                  style: TextStyle(fontSize: 16,)
              ),
            ),
          ),
        ),
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
            '게시글 수정',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        ),
        actions: [],
      ),
      body: Center(
        child: ConstrainedBox(          
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(            
            decoration: BoxDecoration(
              color: Color(0xFFFAFAFA),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold
                    ),
                    decoration: InputDecoration(
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
                  // const SizedBox(height: 8),
                  const Divider(color: Color(0xFFDBDBDB)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
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
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar:  SafeArea(                                    
        child: Container(
          height: 100,
          decoration: BoxDecoration( color: Colors.white),                                      
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
          child:  SizedBox(
            height: 20,
            child: ElevatedButton(
              onPressed: _handleUpdate,
              style: ElevatedButton.styleFrom(
                
                backgroundColor: _isfilled ? Color(0xFFFF002B):const Color(0xFFBDBDBD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                  _isSubmitting ? '작성 중...' : '수정 완료',
                  style: TextStyle(fontSize: 16,)
              ),
            ),
          ),
        ),
      ),
    );
  }
}
