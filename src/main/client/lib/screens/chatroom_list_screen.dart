import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
// import 'package:lucide_icons/lucide_icons.dart';

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
    _fetchChatRooms();
  }

  Future<void> _fetchChatRooms() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final resp = await http.get(
        Uri.parse('http://10.0.2.2:8080/chat'),
        headers: {
          if (token != null) 'Authorization': 'Bearer \$token',
        },
      );
      if (resp.statusCode == 200) {
        setState(() {
          _chatRooms = json.decode(resp.body) as List<dynamic>;
        });
      } else {
        setState(() {
          _error = '채팅방 정보를 불러올 수 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _error = '채팅방 정보를 불러올 수 없습니다.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '내가 참여한 채팅방',
          style: TextStyle(color: Color(0xFF9CB4CD)),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Color(0xFF9CB4CD)),
      ),
      body: _loading
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
              onTap: () => context.push('/chat/\$id'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5FAFF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$current / \$max 명',
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
    );
  }
}
