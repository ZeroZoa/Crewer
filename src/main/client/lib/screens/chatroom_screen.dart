import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

// ChatRoomScreen: 특정 채팅방을 표시하는 StatefulWidget
class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId; // 전달받은 채팅방 ID
  const ChatRoomScreen({Key? key, required this.chatRoomId}) : super(key: key);

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

// ChatRoomScreen의 상태를 관리하는 클래스
class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late StompClient _stompClient; // STOMP 클라이언트 객체
  final List<Map<String, dynamic>> _messages = []; // 수신한 메시지 리스트
  String _nickname = ''; // 내 닉네임
  bool _isConnected = false; // WebSocket 연결 상태

  final TextEditingController _inputController = TextEditingController(); // 메시지 입력 컨트롤러
  final ScrollController _scrollController = ScrollController(); // 메시지 스크롤 컨트롤러

  @override
  void initState() {
    super.initState();
    _loadUserNickname(); // 1) 내 닉네임 로드
    _loadChatHistory();  // 2) 이전 채팅 내역 로드
    _connectStomp();     // 3) STOMP/WebSocket 연결 설정
  }

  @override
  void dispose() {
    _stompClient.deactivate(); // STOMP 연결 해제
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 내 프로필에서 닉네임만 가져오는 메서드
  Future<void> _loadUserNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // 저장된 JWT 토큰
    if (token == null) return;
    final resp = await http.get(
      Uri.parse('http://localhost:8080/profile/me'), // 프로필 API 호출
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      setState(() => _nickname = data['nickname'] ?? ''); // 닉네임 상태 업데이트
    }
  }

  /// 과거 채팅 기록을 서버에서 불러오는 메서드
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final resp = await http.get(
      Uri.parse('http://localhost:8080/chat/${widget.chatRoomId}'), // 채팅 내역 API
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final list = json.decode(resp.body) as List;
      setState(() {
        _messages
          ..clear()
          ..addAll(List<Map<String, dynamic>>.from(list)); // 메시지 리스트에 추가
      });
    }
  }

  /// STOMP/WebSocket 연결 설정 메서드
  void _connectStomp() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: 'http://localhost:8080/ws', // WebSocket 엔드포인트
        stompConnectHeaders: {'Authorization': 'Bearer $token'}, // 헤더에 토큰 추가
        onConnect: _onConnect,           // 연결 성공 콜백
        onWebSocketError: _onWsError,    // WebSocket 에러 콜백
        onStompError: _onStompError,     // STOMP 에러 콜백
        reconnectDelay: const Duration(seconds: 5), // 재연결 지연 시간
      ),
    )..activate(); // 클라이언트 활성화
  }

  /// STOMP 연결 성공 시 호출되는 콜백
  void _onConnect(StompFrame frame) {
    setState(() => _isConnected = true); // 연결 상태 업데이트

    // 채팅방 토픽 구독 (메시지 수신 대기)
    _stompClient.subscribe(
      destination: '/topic/chat/${widget.chatRoomId}',
      callback: _onMessageReceived,
    );
  }

  /// STOMP를 통해 메시지를 수신할 때마다 호출되는 콜백
  void _onMessageReceived(StompFrame frame) {
    if (frame.body == null) return;
    final Map<String, dynamic> message = json.decode(frame.body!);
    setState(() => _messages.insert(0, message)); //불러오는 메세지를 거꾸로 + 내가 보내는 매세지를 맨 아래로 삽입
  }

  /// WebSocket 레벨에서 발생한 에러를 처리하는 콜백
  void _onWsError(dynamic error) {
    debugPrint('WebSocket error: $error');
  }

  /// STOMP 프로토콜 에러 처리 콜백
  void _onStompError(StompFrame frame) {
    debugPrint('STOMP error: ${frame.body}');
  }

  /// 입력창에서 엔터 혹은 전송 버튼 눌렀을 때 호출되는 메서드
  void _handleSend(String _) {
    final text = _inputController.text.trim();
    if (!_isConnected || text.isEmpty) return;
    final payload = json.encode({'content': text});
    _stompClient.send(
      destination: '/app/${widget.chatRoomId}/send', // 메시지 전송 엔드포인트
      body: payload,
    );
    _inputController.clear(); // 입력창 초기화
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 1) 채팅 메시지를 표시하는 리스트
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isMine = m['senderNickname'] == _nickname; // 내 메시지 여부
                final timestamp = DateTime.parse(m['timestamp']).toLocal();
                final time =
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                return Container(
                  margin: EdgeInsets.only(
                    top: 4,
                    bottom: 4,
                    left: isMine ? 50 : 0, // 내 메시지는 오른쪽 여백
                    right: isMine ? 0 : 50, // 상대 메시지는 왼쪽 여백
                  ),
                  child: Align(
                    alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isMine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!isMine)
                          Text(
                            m['senderNickname'] ?? '', // 보낸 사람 닉네임
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            color: isMine ? const Color(0xFF9CB4CD) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: isMine ? null : Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Text(
                            m['content'] ?? '', // 메시지 내용
                            style: TextStyle(
                                color: isMine ? Colors.white : Colors.black87),
                          ),
                        ),
                        Text(
                          time, // 전송 시간 표시
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2) 메시지 입력창 영역
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(LucideIcons.send),
                          color: _isConnected ? const Color(0xFF9CB4CD) : Colors.grey,
                          onPressed: _isConnected ? () => _handleSend('') : null,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _handleSend, // 키보드의 전송 버튼으로도 호출
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
