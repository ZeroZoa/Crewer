import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:client/components/top_navbar.dart';


class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  const ChatRoomScreen({Key? key, required this.chatRoomId}) : super(key: key);

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late StompClient _stompClient;
  final List<Map<String, dynamic>> _messages = [];
  String _nickname = '';
  bool _isConnected = false;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
    _loadChatHistory();
    _connectStomp();
  }

  @override
  void dispose() {
    _stompClient.deactivate();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 내 프로필에서 닉네임만 꺼내기
  Future<void> _loadUserNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final resp = await http.get(
      Uri.parse('http://localhost:8080/profile/me'),
      //Uri.parse('http://10.0.2.2:8080/profile/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      setState(() => _nickname = data['nickname'] ?? '');
    }
  }

  /// 기존 채팅 기록 불러오기
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final resp = await http.get(
      Uri.parse('http://localhost:8080/chat/${widget.chatRoomId}'),
      //Uri.parse('http://10.0.2.2:8080/chat/${widget.chatRoomId}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final list = json.decode(resp.body) as List;
      setState(() {
        _messages
          ..clear()
          ..addAll(List<Map<String, dynamic>>.from(list));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: 5), () {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      });
    }
  }

  /// SockJS 업그레이드 방식으로 STOMP/WebSocket 연결
  void _connectStomp() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: 'http://localhost:8080/ws',
        //url: 'http://10.0.2.2:8080/ws',
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: _onConnect,
        onWebSocketError: _onWsError,
        onStompError: _onStompError,
        reconnectDelay: const Duration(seconds: 5),
      ),
    )..activate();
  }

  /// ① STOMP 연결이 성공했을 때 호출됩니다.
  void _onConnect(StompFrame frame) {
    setState(() => _isConnected = true);

    // 채팅방 토픽 구독
    _stompClient.subscribe(
      destination: '/topic/chat/${widget.chatRoomId}',
      callback: _onMessageReceived,
    );
  }

  /// ② 메시지가 도착할 때마다 호출됩니다.
  void _onMessageReceived(StompFrame frame) {
    if (frame.body == null) return;
    final Map<String, dynamic> message = json.decode(frame.body!);
    setState(() => _messages.add(message));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 5), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    });
  }

  /// ③ WebSocket 레벨에서 에러가 발생했을 때
  void _onWsError(dynamic error) {
    debugPrint('WebSocket error: $error');
    // (선택) 사용자에게 토스트 띄우기 등
  }

  /// ④ STOMP 프로토콜 에러가 발생했을 때
  void _onStompError(StompFrame frame) {
    debugPrint('STOMP error: ${frame.body}');
    // (선택) 재연결 로직, 사용자 알림 등
  }

  /// 메시지 전송
  void _handleSend(String _) {
    final text = _inputController.text.trim();
    if (!_isConnected || text.isEmpty) return;
    final payload = json.encode({'content': text});
    _stompClient.send(
      destination: '/app/${widget.chatRoomId}/send',
      body: payload,
    );
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(onBack: () => context.pop()),
      body: Column(
        children: [
          // 1) 메시지 리스트
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isMine = m['senderNickname'] == _nickname;
                final timestamp = DateTime.parse(m['timestamp'])
                    .toLocal();
                final time =
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                return Container(
                  margin: EdgeInsets.only(
                    top: 4,
                    bottom: 4,
                    left: isMine ? 50 : 0,
                    right: isMine ? 0 : 50,
                  ),
                  child: Align(
                    alignment:
                    isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isMine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!isMine)
                          Text(
                            m['senderNickname'] ?? '',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[700]),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            color: isMine
                                ? const Color(0xFF9CB4CD)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: isMine
                                ? null
                                : Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          child: Text(
                            m['content'] ?? '',
                            style: TextStyle(
                                color: isMine ? Colors.white : Colors.black87),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2) 입력창
          SafeArea(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: Colors.grey.shade200)),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(LucideIcons.send),
                          color: _isConnected
                              ? const Color(0xFF9CB4CD)
                              : Colors.grey,
                          onPressed:
                          _isConnected ? () => _handleSend('') : null,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding:
                        const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _handleSend,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// 스크롤을 맨 아래로
// void _scrollToBottom() {
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     _scrollController.animateTo(
//       _scrollController.position.maxScrollExtent,
//       duration: const Duration(milliseconds: 200),
//       curve: Curves.easeOut,
//     );
//   });
// }