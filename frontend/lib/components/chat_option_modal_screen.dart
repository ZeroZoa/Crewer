import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ChatOptionModalScreen extends StatefulWidget {
  final String chatRoomId;

  const ChatOptionModalScreen({super.key, required this.chatRoomId});  

  @override
  _ChatOptionModalScreenState createState() => _ChatOptionModalScreenState();
}

class _ChatOptionModalScreenState extends State<ChatOptionModalScreen> {
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


  // 모임 종료 처리
  Future<void> _endMeeting() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _showEndMeetingDialog(context)
    );
    if (confirm != true) return;
    //로그인 체크
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return;
    
     try {   
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.completeGroupFeed(widget.chatRoomId)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
    
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final message = responseBody['message'] ?? '모임이 종료되었습니다.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        // 알림 페이지로 이동하지 않음 (현재 화면 유지)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모임 종료에 실패했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }

  //채팅방 나가기
  Future<void> _handleExit() async {
    // 1) 삭제 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _exitChatRoomWidget(context)
    );
    if (confirm != true) return;

    // 2) 로그인 체크
    final token = await _storage.read(key: _tokenKey);
    
    if (token == null) {
      _showLoginModal();
      return;
    }
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getExitChatRoom(widget.chatRoomId)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      context.pop();
      context.pop();

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('방 나가기에 실패했습니다. 그룹피드가 삭제되지 않았는지 확인해주세요')),
        );
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }


  }

  // 채팅방 나가기 알림창
  Widget _exitChatRoomWidget(BuildContext context){
    return AlertDialog(
      backgroundColor: Colors.white,
          title: Center(
            child: Column(
              children: [ 
                SizedBox(height: 30,),
                const Text('정말 이 채팅방을 나가시겠습니까?',
                      style: TextStyle(fontSize: 18,                    
                      fontWeight: FontWeight.bold)
                ),
                SizedBox(height: 30,)
              ],
              
            ),
          ),                                                                             
          actions: [ 
            ElevatedButton(
              onPressed: () => context.pop(),
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
                '나가기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
      );
  }

   /// 모임 종료 확인 알림창
  Widget _showEndMeetingDialog(BuildContext context)                    {
    return AlertDialog(
      backgroundColor: Colors.white,
          title: Center(
            child: Column(
              children: [ 
                SizedBox(height: 30,),
                const Text('정말 이 모임을 종료하시겠습니까?',
                      style: TextStyle(fontSize: 18,                    
                      fontWeight: FontWeight.bold)
                ),
                SizedBox(height: 30,)
              ],
              
            ),
          ),                                                                             
          actions: [ 
            ElevatedButton(
              onPressed: () => context.pop(),
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
                '종료하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
      );
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
                    onPressed:_endMeeting,
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
                        const Icon(LucideIcons.handshake,
                        color: Color(0xFF767676),
                        size: 20,),
                        const SizedBox(width: 8),
                        Text("모임 종료", 
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
                    onPressed:_handleExit,
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
                        const Icon(LucideIcons.log_out,
                        color: Color(0xFFFF002B),
                        size: 20,),
                        const SizedBox(width: 8),
                        Text("채팅방 나가기", 
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