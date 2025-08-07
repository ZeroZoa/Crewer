import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';
import '../config/api_config.dart';

/// 참여한 채팅방 목록 화면
class ChatRoomListScreen extends StatefulWidget {
  const ChatRoomListScreen({Key? key}) : super(key: key);

  @override
  _ChatRoomListScreenState createState() => _ChatRoomListScreenState();
}

class _ChatRoomListScreenState extends State<ChatRoomListScreen> {
  List<dynamic> _chatRooms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetch();
  }
  // 로그인 및 기록 조회
  Future<void> _checkLoginAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      // 로그인 모달 표시
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => LoginModalScreen(),
      );
      // 모달 닫힌 뒤에도 여전히 비로그인 상태라면 이전 화면으로 돌아감
      final newToken = prefs.getString('token');
      if (newToken == null) {
        context.pop();
      } else {
        setState(() {}); // 로그인 후 화면 갱신
      }
    }
    else{
      await _fetchChatRooms(token);
    }
  }

  Future<void> _fetchChatRooms(String token) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    try {
      final headers = {'Authorization': 'Bearer $token'};
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chat}'),
        headers: headers,
      );
      if (resp.statusCode == 200) {
        _chatRooms = json.decode(resp.body) as List<dynamic>;
      } else if (resp.statusCode == 403 || resp.statusCode == 401) {
        // 토큰 만료 시 로그인 모달 띄우고, 모달이 반환한 새 토큰을 받는다.
        final newToken = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          builder: (_) => LoginModalScreen(),
        );

        // 사용자가 로그인 모달을 취소했으면 화면 닫기
        if (newToken == null) {
          context.pop();
          return;
        }

        // 받은 새 토큰을 SharedPreferences에 저장
        await prefs.setString('token', newToken);

        // 재귀 호출로 다시 fetch (새 토큰을 전달)
        return _fetchChatRooms(newToken);
      }
      else{
        _error = '채팅방 정보를 불러올 수 없습니다.';
      }
    } catch(e) {
      _error = '채팅방 정보를 불러올 수 없습니다.';
    } finally{
      if(mounted){
        setState(() {
          _loading = false;
        });
      }
    }
  }

// Future<void> _fetchDirectChatRooms() async {
//   final prefs = await SharedPreferences.getInstance();
//   String? token = prefs.getString('token');

//   // 로그인 안 돼 있으면 로그인 모달 띄우기
//   if (token == null) {
//     final newToken = await showModalBottomSheet<String>(
//       context: context,
//       isScrollControlled: true,
//       builder: (_) => LoginModalScreen(),
//     );

//     if (newToken == null) {
//       context.pop(); // 로그인 안 했으면 화면 닫기
//       return;
//     }

//     token = newToken;
//     await prefs.setString('token', newToken);
//   }

//   setState(() {
//     _loading = true;
//     _error = null;
//   });

//   try {
//     final headers = {'Authorization': 'Bearer $token'};
//     final resp = await http.get(
//       Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupChat()}'),
//       headers: headers,
//     );

//     if (resp.statusCode == 200) {
//       _chatRooms = json.decode(resp.body) as List<dynamic>;
//     } else if (resp.statusCode == 401 || resp.statusCode == 403) {
//       // 로그인 만료 → 다시 로그인 유도
//       final newToken = await showModalBottomSheet<String>(
//         context: context,
//         isScrollControlled: true,
//         builder: (_) => LoginModalScreen(),
//       );

//       if (newToken == null) {
//         context.pop(); // 로그인 안 했으면 종료
//         return;
//       }

//       await prefs.setString('token', newToken);
//       return _fetchDirectChatRooms(); // 새 토큰으로 재시도
//     } else {
//       _error = '채팅방 정보를 불러올 수 없습니다.';
//     }
//   } catch (e) {
//     _error = '채팅방 정보를 불러올 수 없습니다.';
//   } finally {
//     if (mounted) {
//       setState(() {
//         _loading = false;
//       });
//     }
//   }
// }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize( 
        preferredSize: Size.fromHeight(60),
        child: Container(
        padding: EdgeInsets.only(top: 20, left: 10),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              margin:EdgeInsets.fromLTRB(5, 0,5, 0),     
              child: ElevatedButton(
                onPressed:(){
                  print("버튼1 눌림");
                },
                style: ElevatedButton.styleFrom(
                   backgroundColor: Color(0xFF9CB4CD), 
                   
                ),
                child: 
                Text("그룹 채팅",
                  style: TextStyle(color: Colors.white)), 
              ),
            ),
            ElevatedButton(
              onPressed:(){ },
               style: ElevatedButton.styleFrom(
                 backgroundColor: Color(0xFF9CB4CD),     
              ),
              child: 
                Text("다이렉트 채팅",
                style: TextStyle(color: Colors.white)),
            ), 
          ],
        ),
        ),
      ),
      body: Container(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          )
              : Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: _chatRooms.isNotEmpty
                  ? _chatRooms.map((room) {
                final id = room['id'].toString();
                final name = room['name'] ?? '';
                final current = room['currentParticipants'] ?? 0;
                final max = room['maxParticipants'] ?? 1;
                final percent = max > 0 ? current / max : 0.0;
                return GestureDetector(
                  onTap: () => context.push('/chat/$id'),
                  child: Container(
                    margin: const EdgeInsets.only(top: 1,bottom: 1),
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$current / $max 명',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: percent.clamp(0.0, 1.0),
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9CB4CD),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Divider(thickness: 1,),
                      ],
                    ),
                  ),
                );
              }).toList()
                  : [
                Center(
                  child: Text(
                    '참여 중인 채팅방이 없습니다.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}