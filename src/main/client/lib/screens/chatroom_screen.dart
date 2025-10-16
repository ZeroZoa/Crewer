import 'dart:convert';

import 'package:client/components/chat_option_modal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../components/custom_app_bar.dart';
import '../config/api_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  Map<String, dynamic>? _chatRoom={};
  String _nickname = ''; // 내 닉네임
  bool _isConnected = false; // WebSocket 연결 상태
  bool _isGroupChat = false; // 그룹 채팅 여부

  final TextEditingController _inputController = TextEditingController(); // 메시지 입력 컨트롤러
  final ScrollController _scrollController = ScrollController(); // 메시지 스크롤 컨트롤러
  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserNickname(); // 내 닉네임 로드
    _loadChatHistory();  // 이전 채팅 내역 로드
    _loadChatRoom(); // 채팅방 정보
    _connectStomp();     // STOMP/WebSocket 연결 설정
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
    final token = await _storage.read(key: _tokenKey);

    if (token == null) return;
    final resp = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}/me'), // 프로필 API 호출
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      setState(() => _nickname = data['nickname'] ?? ''); // 닉네임 상태 업데이트
    }
  }
  //채팅방 정보를 가져오는 메서드
   Future<void> _loadChatRoom() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) return;
    final resp = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chat}/getchatroom/${widget.chatRoomId}'), // 프로필 API 호출
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      _chatRoom = data;
      
      // 그룹 채팅 여부 판단 (채팅방 타입이 'GROUP'이면 그룹 채팅)
      setState(() {
        _isGroupChat = _chatRoom?['type'] == 'GROUP';
      });
    }
  }
  // 과거 채팅 기록을 서버에서 불러오는 메서드
  Future<void> _loadChatHistory() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) return;
    final resp = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chat}/${widget.chatRoomId}'), // 채팅 내역 API
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

  //이미지 선택할수 있게 창이 뜨는 메서드
  Future<void> _pickImage() async {
  final ImagePicker _picker = ImagePicker();
  final XFile? pickedFile = await _picker.pickImage(
    source: ImageSource.gallery,
    maxHeight: 200,
    maxWidth: 200,
    imageQuality: 100, );

  if (pickedFile != null) {
    File imageFile = File(pickedFile.path);
    print('이미지 선택됨: ${imageFile.path}');
    // 여기서 서버 업로드 함수 호출
    await _imageUpload(imageFile);
    }
  }

  // 이미지 서버 업로드 메서드
  Future<void> _imageUpload(imageFile) async {

   final token = await _storage.read(key: _tokenKey);

    if (token == null) return;
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.uploadImage()}');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] =  'Bearer $token'
      ..files.add(
        await http.MultipartFile.fromPath(
          'image',
           imageFile.path),
    );
    final resp = await request.send();

    if (resp.statusCode == 200) {
      final path = await resp.stream.bytesToString();
      if (!_isConnected || path.isEmpty) return;
      final payload = json.encode({'type':'IMAGE','content': path});
      _stompClient.send(
        destination: '/app/${widget.chatRoomId}/send', // 메시지 전송 엔드포인트
        body: payload,
      );
    }
  }

  // STOMP/WebSocket 연결 설정 메서드
  void _connectStomp() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return;

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: '${ApiConfig.baseUrl}${ApiConfig.ws}', // SockJS 엔드포인트 (http:// 사용)
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
    final payload = json.encode({'type':'TEXT','content': text});
    _stompClient.send(
      destination: '/app/${widget.chatRoomId}/send', // 메시지 전송 엔드포인트
      body: payload,
    );
    _inputController.clear(); // 입력창 초기화
  }


  void _showOptionModal() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => ChatOptionModalScreen(chatRoomId : widget.chatRoomId),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarType: _isGroupChat ? AppBarType.backWithMore : AppBarType.backOnly,
        title: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 36, top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '채팅방',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(width: 6,),
              Text(
                '${_chatRoom?['currentParticipants']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF767676),
                ),
              ),
            ]
          )
        ),
        actions:[
          if(_isGroupChat == true)
            IconButton(
              onPressed: _showOptionModal,
              icon: const Icon(LucideIcons.moreVertical),
            ),
        ],
      ),
      backgroundColor: Color(0xFFFAFAFA),
      body: Column(
        children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final message = _messages[i];
                  final isMine = message['senderNickname'] == _nickname; // 내 메시지 여부
                  final timestamp = DateTime.parse(message['timestamp']).toLocal();
                  final time =
                      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                  Widget contentWidget;
                  if (message['type']=='IMAGE'){
                    contentWidget = Image.network(
                      ApiConfig.baseUrl+message['content'],
                      errorBuilder: (context, error, stackTrace) {
                        print("로딩 실패 $error");
                        return const Icon(Icons.error, size: 100, color: Colors.red);
                      },
                    );
                  }else{
                    contentWidget = Text(
                              message['content'] ?? '', // 메시지 내용
                              style: TextStyle(
                                  color: isMine ? Colors.black : Colors.black87),
                            );
                  }
                  Widget messageBubble =  Container(
                            constraints: BoxConstraints(maxWidth: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMine)
                                Text(
                                  message['senderNickname'] ?? '', // 보낸 사람 닉네임
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                               Container(
                                decoration: BoxDecoration(
                                  color: isMine ? const Color(0xFFAFAFAF) : Color(0xFFE6E6E6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: isMine ? null : Border.all(color: Colors.grey.shade300),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: contentWidget,
                              ),
                              
                              ],
                              
                            ),
                          );
                  return Container(
                    margin: EdgeInsets.only(
                      top: 4,
                      bottom: 4,
                      left: isMine ? 50 : 0, // 내 메시지는 오른쪽 여백
                      right: isMine ? 0 : 50, // 상대 메시지는 왼쪽 여백
                    ),
                        child: Row(
                          mainAxisAlignment: isMine
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: !isMine ? [
                            CircleAvatar(
                              radius: 15,
                              backgroundImage: NetworkImage(ApiConfig.baseUrl+message['senderAvatarUrl']),
                            ),
                         messageBubble,
                           Text(
                              time, // 전송 시간 표시
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                          ]:[
                            Text(
                              time, // 전송 시간 표시
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                            messageBubble,
                            ],
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
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFE6E6E6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.image, color: Colors.black),
                      onPressed:(){_pickImage();} ,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        hintStyle: TextStyle(color: Colors.grey[800], fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      ),
                    ),
                  ),

                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(left: 8.0), // TextField와의 간격
                    decoration: const BoxDecoration(
                      color: Colors.red,       // 배경색을 빨간색으로
                      shape: BoxShape.circle,  // 모양을 동그랗게
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        LucideIcons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isConnected ? () => _handleSend('') : null,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

