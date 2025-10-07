import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class FeedOptionModalScreen extends StatefulWidget {
  final String feedId;
  final bool isFeed;

  const FeedOptionModalScreen({super.key, required this.feedId, required this.isFeed});  

  @override
  _FeedOptionModalScreenState createState() => _FeedOptionModalScreenState();
}

class _FeedOptionModalScreenState extends State<FeedOptionModalScreen> {
  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    super.dispose();
  }

    void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginModalScreen(),
    );
  }
  // 삭제 알림창
  Widget _deleteWidget(BuildContext context){
    return AlertDialog(
      backgroundColor: Colors.white,
          title: Center(
            child: Column(
              children: [ 
                SizedBox(height: 30,),
                const Text('이 게시글을 삭제하시겠습니까?',
                      style: TextStyle(fontSize: 18,                    
                      fontWeight: FontWeight.bold)
                ),
                SizedBox(height: 30,)
              ],
              
            ),
          ),                                                                             
          actions: [ 
            ElevatedButton(
              onPressed: () => context.pop(false),
              style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 36, vertical: 15),
              backgroundColor: Color(0xFFEEEEEE),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
              ),
              child: const Text(
                '취소하기',
                style: TextStyle(
                  color: Color(0xFF767676),
                  fontSize: 16,
                ),
              ),
            ),                     
            ElevatedButton(
              onPressed: () => context.pop(true),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 36, vertical: 15),
                backgroundColor: Color(0xFFFF002B),
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Text(
                '삭제하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
      );
  }

 //수정 페이지 이동 + 권한 확인
  Future<void> _handleEdit() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      _showLoginModal();
      return;
    }
    context.pop();
    widget.isFeed ? 
    context.push('/feeds/${widget.feedId}/edit')
    : context.push('/groupfeeds/${widget.feedId}/edit');
  }

  //삭제 페이지 이동 + 권한 확인
  Future<void> _handleDelete() async {
    // 1) 삭제 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _deleteWidget(context)
    );
    if (confirm != true) return;

    // 2) 로그인 체크
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      _showLoginModal();
      return;
    }    
     // 실제 삭제 요청
    await http.delete(
      widget.isFeed ? 
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getFeedDetail(widget.feedId)}'):
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedDetail(widget.feedId)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    context.pop();
    widget.isFeed ? 
    context.replace('/feeds') 
    : context.replace('/groupfeeds'); 
    
  }


  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: FractionallySizedBox(
        heightFactor: bottomInset > 0 ? 1 : 0.35, // 키보드가 올라오면 높이를 늘림
        alignment: bottomInset > 0 ? Alignment.topCenter : Alignment.bottomCenter, // 키보드가 올라오면 상단 정렬
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(            
            mainAxisSize: MainAxisSize.min,
            children: [                                        
                  ElevatedButton(
                    onPressed:_handleEdit,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                    backgroundColor: Color(0xFFEEEEEE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.pencil_line,
                        color: Color(0xFF767676),
                        size: 20,),
                        const SizedBox(width: 8),
                        Text("게시글 수정", 
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF767676),
                          
                        ),)
                      ],
                    )                    
                  ),
                  const SizedBox(height: 8),
                  
                  // 삭제 버튼
                  ElevatedButton(
                    onPressed:_handleDelete,
                    style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                    backgroundColor: Color(0xFFEEEEEE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.trash_2,
                        color: Color(0xFFFF002B),
                        size: 20,),
                        const SizedBox(width: 8),
                        Text("삭제", 
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFF002B),
                          
                        ),)
                      ],
                    )                    
                  ),

              const SizedBox(height: 20),
              
              // 닫기 버튼
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: (){Navigator.pop(context);},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2B2D42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                          '닫기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),              
            ],
          ),
        ),
      ),
    );
  }
}