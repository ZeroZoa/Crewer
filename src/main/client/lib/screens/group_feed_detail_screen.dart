import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/components/login_modal_screen.dart';
import '../config/api_config.dart';

/// 그룹 피드 상세 화면
class GroupFeedDetailScreen extends StatefulWidget {
  final String groupFeedId;
  const GroupFeedDetailScreen({Key? key, required this.groupFeedId}) : super(key: key);

  @override
  _GroupFeedDetailScreenState createState() => _GroupFeedDetailScreenState();
}

class _GroupFeedDetailScreenState extends State<GroupFeedDetailScreen> {
  Map<String, dynamic>? _groupFeed;
  List<dynamic> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool _loading = true;
  bool _error = false;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.wait([
      _fetchGroupFeed(),
      _fetchComments(),
      _fetchLikeStatus(),
    ]);
    setState(() => _loading = false);
  }

  Future<void> _fetchGroupFeed() async {
    try {
      final resp = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedDetail(widget.groupFeedId)}'));
      if (resp.statusCode == 200) {
        _groupFeed = json.decode(resp.body);
      } else {
        _error = true;
      }
    } catch (_) {
      _error = true;
    }
  }

  Future<void> _fetchComments() async {
    try {
      final resp = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedComments(widget.groupFeedId)}'));
      if (resp.statusCode == 200) {
        _comments = (json.decode(resp.body) as List).reversed.toList();
      }
    } catch (_) {}
  }

  Future<void> _fetchLikeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedLikeStatus(widget.groupFeedId)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        _isLiked = json.decode(resp.body) as bool;
      }
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      _showLoginModal();
      return;
    }
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedLike(widget.groupFeedId)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      await _fetchLikeStatus();
      setState(() {});
    } catch (_) {}
  }

  Future<void> _toggleParticipation() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      _showLoginModal();
      return;
    }
    try {
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedJoinChat(widget.groupFeedId)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(resp.body);
      context.push('/chat/${data['id']}');
    } catch (_) {}
  }

  Future<void> _handleCommentSubmit() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      _showLoginModal();
      return;
    }
    try {
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedComments(widget.groupFeedId)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': text}),
      );
      if (resp.statusCode == 201) {
        final comment = json.decode(resp.body);
        _comments.insert(0, comment);
        _commentController.clear();
        setState(() {});
      }
    } catch (_) {}
  }

  // 수정: 로그인 체크 후 이동
  Future<void> _handleEdit() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      _showLoginModal();
      return;
    }
    context.push('/groupfeeds/${widget.groupFeedId}/edit');
  }

  Future<void> _handleDelete() async {
    // 1) 삭제 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // 2) 로그인 체크
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      _showLoginModal();
      return;
    }

    // 3) 실제 삭제 요청
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedDetail(widget.groupFeedId)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    context.replace('/');
  }

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginModalScreen(),
    ).then((_) => _loadData());
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    return d.toLocal().toString().substring(0, 19);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error || _groupFeed == null) {
      return Scaffold(
        body: const Center(child: Text('데이터를 불러올 수 없습니다.')),
      );
    }
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _groupFeed!['title'] ?? '',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () async {
                                // 작성자의 프로필로 이동
                                final authorUsername = _groupFeed!['authorUsername'];
                                if (authorUsername != null) {
                                  // 현재 사용자의 username 가져오기
                                  final prefs = await SharedPreferences.getInstance();
                                  final token = prefs.getString('token');
                                  String? currentUsername;
                                  
                                  if (token != null) {
                                    try {
                                      final response = await http.get(
                                        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfileMe()}'),
                                        headers: {'Authorization': 'Bearer $token'},
                                      );
                                      if (response.statusCode == 200) {
                                        final profile = json.decode(response.body);
                                        currentUsername = profile['username'];
                                      }
                                    } catch (e) {
                                      print('현재 사용자 정보 로드 실패: $e');
                                    }
                                  }
                                  
                                  // 현재 사용자인지 확인하여 적절한 페이지로 이동
                                  if (currentUsername == authorUsername) {
                                    context.push('/profile'); // 내 프로필
                                  } else {
                                    context.push('/user/$authorUsername'); // 다른 사용자 프로필
                                  }
                                }
                              },
                              child: Text(
                                '${_groupFeed!['authorNickname']} | ${_formatDate(_groupFeed!['createdAt'])}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      //수정 삭제를 위한 팝업 버튼
                      PopupMenuButton<String>(
                        icon: const Icon(LucideIcons.moreVertical),
                        onSelected: (value) {
                          if (value == 'edit') _handleEdit();
                          if (value == 'delete') _handleDelete();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('수정'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('삭제',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0), // 세로 여백
                  // 본문
                  Text(
                    _groupFeed!['content'] ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  // 좋아요 버튼과 댓글 수
                  Row(
                    children: [
                      Text(
                        '댓글 ${_comments.length}',
                        style: const TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : LucideIcons.heart,
                          color: const Color(0xFF9CB4CD),
                        ),
                        iconSize: 28,
                        onPressed: _toggleLike,
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _toggleParticipation,
                        label: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Crew',
                                style: TextStyle(
                                  fontFamily: 'CustomFont',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: ' 참여',
                                style: TextStyle(
                                  // default font; just omit fontFamily
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9CB4CD),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    color: Color(0xFF9CB4CD),
                    thickness: 2.0,
                    indent: 0,
                    endIndent: 0,
                  ),
                  if(_comments.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Icon(LucideIcons.laugh, size: 70, color: Color(0xFF9CB4CD)),
                          const SizedBox(height: 16),
                          const Text(
                            '첫 번째 댓글을 남겨주세요!',
                            style: TextStyle(
                              color: Color(0xFF677888),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: Color(0xFF9CB4CD),
                        indent: 12,
                        endIndent: 12,
                      ),
                      itemBuilder: (context, index) {
                        final c = _comments[index];
                        return ListTile(
                          title: Text(c['content'] ?? ''),
                          subtitle: Text(
                            '${c['authorNickname'] ?? '익명'} | ${_formatDate(c['createdAt'])}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        );
                      },
                    ),
                ],
              ),
            )
          ),
          SafeArea(
            child: Container(
                height: 75,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  color: Colors.white,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                              hintText: '댓글을 입력하세요',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: const Color(0xF2E4E7EA),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              suffixIcon: IconButton(
                                icon: const Icon(LucideIcons.send),
                                onPressed: _handleCommentSubmit,
                              )
                          ),
                        ),
                      ),
                    ],
                  ),
                )
            ),
          ),
        ],
      ),
    );
  }
}
