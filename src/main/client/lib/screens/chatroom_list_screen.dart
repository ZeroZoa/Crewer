import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/custom_app_bar.dart';
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
  bool isGroupSelected =true;
  bool isDirect = false;

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndFetch();
    });

  }
  // 로그인 및 기록 조회
  Future<void> _checkLoginAndFetch() async {
    developer.log('4. _checkLoginAndFetch 시작', name: 'RankingScreen');
    final token = await _storage.read(key: _tokenKey);
    developer.log('5. 저장된 토큰 값: $token', name: 'RankingScreen');
    if (token == null) {
      developer.log('6. 토큰 없음 -> 로그인 모달 표시 시도', name: 'RankingScreen');
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
      } else {
        setState(() {}); // 로그인 후 화면 갱신
      }
    }
    else{
      developer.log('7. 토큰 있음 -> 데이터 로딩 시작', name: 'RankingScreen');
      await _fetchChatRooms();
    }
  }

  Future<void> _fetchChatRooms() async {

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: _tokenKey);

      final headers = {'Authorization': 'Bearer $token'};

      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupChat()}'),
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
        await _storage.write(key: _tokenKey, value: newToken);

        // 재귀 호출로 다시 fetch (새 토큰을 전달)
        return _fetchChatRooms();
      }
      else{
        _error = '채팅방 정보를 불러올 수 없습니다.';
      }
    } catch(e) {
      _error = '채팅방 정보를 불러올 수 없습니다.';
    } finally{
      if(mounted){
        setState(() {
          isGroupSelected = true;
          isDirect = false;
          _loading = false;
        });
      }
    }
  }

Future<void> _fetchDirectChatRooms() async {

  setState(() {
    _loading = true;
    _error = null;
  });

  String? token = await _storage.read(key: _tokenKey);

  try {
    final headers = {'Authorization': 'Bearer $token'};

    final resp = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getDirectChat()}'),
      headers: headers,
    );

    if (resp.statusCode == 200) {
      _chatRooms = json.decode(resp.body) as List<dynamic>;
    } else if (resp.statusCode == 401 || resp.statusCode == 403) {

      // 로그인 만료 → 다시 로그인 유도
      final newToken = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (_) => LoginModalScreen(),
      );

      if (newToken == null) {
        context.pop(); // 로그인 안 했으면 종료
        return;
      }

      await _storage.write(key: _tokenKey, value: newToken);
      return _fetchDirectChatRooms(); // 새 토큰으로 재시도
    } else {
      _error = '채팅방 정보를 불러올 수 없습니다.';
    }
  } catch (e) {
    _error = '채팅방 정보를 불러올 수 없습니다.';
  } finally {
    if (mounted) {
      setState(() {
         isGroupSelected = false;
         isDirect = true;
        _loading = false;
      });
    }
  }
}


String getRelativeTime(String isoTimeString) {
  if (isoTimeString == null || isoTimeString.isEmpty){
    return '';
  }
  try{DateTime sentTime = DateTime.parse(isoTimeString).toLocal(); // UTC → local
  DateTime now = DateTime.now();
  Duration diff = now.difference(sentTime);

  if (diff.inSeconds < 60) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';

  // 일주일 넘으면 날짜로 표시
  return '${sentTime.year}.${sentTime.month.toString().padLeft(2, '0')}.${sentTime.day.toString().padLeft(2, '0')}';}
  catch(e){return '';}

}



  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: CustomAppBar(
        appBarType: AppBarType.main,
        onMainSearchPressed: () {
          context.push('/chatroomsearch');
        },
        onNotificationPressed: () {
          context.push('/notifications');
        },
        leading: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 20.0, top: 4),
          child: const Text(
            '채팅',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
            )
          )
        )
      ),
      backgroundColor: Color(0xFFFAFAFA),
      body: Column(
        children: [
          Container(
            width: screenWidth*0.9,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: Duration(milliseconds: 200),
                  alignment: isGroupSelected ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    width: screenWidth*0.45,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {_fetchChatRooms();},
                        child: Center(
                          child: Text(
                            '그룹채팅',
                            style: TextStyle(
                              color: isGroupSelected ? Color(0xFF2B2D42) : Color(0xFF999999),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {_fetchDirectChatRooms();},
                        child: Center(
                          child: Text(
                            '1:1 채팅',
                            style: TextStyle(
                              color: !isGroupSelected ? Color(0xFF2B2D42) : Color(0xFF999999),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
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
                    final name = isDirect ?  room['nickname'] : room['name'];
                    final current = room['currentParticipants'] ?? 0;
                    final max = room['maxParticipants'] ?? 1;
                    String lastText = room['lastContent'] ?? '';
                    final lastSendAt = room['lastSendAt'] ?? '';
                    final lastType = room['lastType'] ?? '';
                    if(lastType == "IMAGE"){lastText = '사진을 보냈습니다.';}
                    final String? avatarUrl = room['avatarUrl'];                    
                    Widget _profileAvartar=const SizedBox.shrink();
                    if (avatarUrl ==null || avatarUrl.isEmpty){
                      _profileAvartar = const CircleAvatar(
                          radius: 25,
                          backgroundColor: Color(0xffeeeeee),
                          child: Icon(LucideIcons.user, color: Color(0xff999999),),
                        );
                    }
                      if(isDirect == false){
                       if(current == 2) {                      
                        _profileAvartar = SizedBox(
                          width: 50,
                          height:50,
                          child: Stack(children: [
                              for (int i = 0; i < 2; i++)
                              Positioned(
                                // 💡 i 값에 따라 위치를 왼쪽으로 조금씩 이동시켜 겹치는 효과를 만듦
                                left: i * 10,
                                top: i* 10, 
                                child: const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color(0xffeeeeee),
                                  child: Icon(LucideIcons.user, color: Color(0xff999999)),
                                ),
                              ),                              
                              ].reversed.toList(),),
                        );
                       }else if(current == 3){                         
                          _profileAvartar = SizedBox(
                              width: 50,
                              height:50,
                              child: Stack(children: [
                                 for (int i = 0; i < 3; i++)
                                  Positioned(
                                    // 💡 i 값에 따라 위치를 이동
                                    left: i==0?10:(i-1)*18,
                                    top: i==0 ? 0: 15,
                                    child: const CircleAvatar(
                                      radius: 15,
                                      
                                      backgroundColor: Color(0xffeeeeee),
                                      child: Icon(LucideIcons.user, color: Color(0xff999999)),
                                    ),
                                  ),                              
                                  ].reversed.toList(),),
                            );
                          }else if(current >=4){
                          _profileAvartar = SizedBox(
                              width: 50,
                              height:50,
                              child: Stack(children: [
                                 for (int i = 0; i < 4; i++)
                                  Positioned(
                                    // 💡 i 값에 따라 위치를 이동
                                    left: (i%2)*15,
                                    top: i<=2? 0 : 15, 
                                    child: const CircleAvatar(
                                      radius:15,
                                      backgroundColor: Color(0xffeeeeee),
                                      child: Icon(LucideIcons.user, color: Color(0xff999999)),
                                    ),
                                  ),                              
                                  ].reversed.toList(),),
                            );
                        }                                                         
                      }else{
                        _profileAvartar = CircleAvatar(
                          radius: 25,
                          backgroundImage:NetworkImage(ApiConfig.baseUrl+avatarUrl!),
                        );
                      }
                    
                    return GestureDetector(
                      onTap: () => context.push('/chat/$id'),
                      child: Container(                      
                        margin: const EdgeInsets.only(top: 1,bottom: 1),
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                               _profileAvartar,
                                Container(                                
                                  margin: EdgeInsets.symmetric(horizontal: 20),
                                child : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [ 
                                      Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 7,),
                                      Visibility(
                                        visible: isDirect ? false: true,
                                        child: Row(
                                          children: [
                                            Text(
                                            '$current',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF767676),
                                            ),
                                            ),
                                          Text(' / $max 명',
                                           style: const TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFFBDBDBD),
                                            ),),
                                          ],
                                          
                                        ),
                                    ),
                                    ]),
                                     Container(
                                      width: 200,
                                       child: Text(
                                          lastText,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF767676),
                                          ),
                                        ),
                                     ),
                                  ],
                                ),
                                ),
                                    Spacer(),
                                     Text(
                                      getRelativeTime(lastSendAt),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color:Color(0xFFBDBDBD),
                                      ),
                                    ),
                              ],
                            ),
                            const SizedBox(height: 15),
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
        ],
      ),
    );
  }
}