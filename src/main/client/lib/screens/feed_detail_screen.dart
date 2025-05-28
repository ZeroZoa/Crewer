import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP 요청
import 'dart:convert'; // JSON 변환
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 토큰 관리
import 'package:client/components/top_navbar.dart'; // 상단 네비게이션바
import 'package:client/components/login_modal_screen.dart'; // 로그인 모달

/// 피드 상세 화면
/// feedId에 해당하는 피드 정보를 서버에서 가져와 Flutter로 렌더링합니다.
class FeedDetailScreen extends StatefulWidget {
  final String feedId;
  const FeedDetailScreen({Key? key, required this.feedId}) : super(key: key);

  @override
  _FeedDetailScreenState createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  Map<String, dynamic>? _feed;
  List<dynamic> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool _loading = true;
  bool _error = false;
  bool _isLiked = false;
  // ✅ _showOptions 상태 변수 삭제로 코드 간소화 ✅

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

  /// 상세, 댓글, 좋아요 상태 동시 로드
  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.wait([
      _fetchDetail(),
      _fetchComments(),
      _fetchLikeStatus(),
    ]);
    setState(() => _loading = false);
  }

  Future<void> _fetchDetail() async {
    try {
      final resp = await http.get(
        Uri.parse('http://localhost:8080/feeds/${widget.feedId}'),
        //Uri.parse('http://10.0.2.2:8080/feeds/${widget.feedId}'),
      );
      if (resp.statusCode == 200) {
        _feed = json.decode(resp.body);
      } else {
        _error = true;
      }
    } catch (_) {
      _error = true;
    }
  }

  Future<void> _fetchComments() async {
    try {
      final resp = await http.get(
        Uri.parse('http://localhost:8080/feeds/${widget.feedId}/comments'),
        //Uri.parse('http://10.0.2.2:8080/feeds/${widget.feedId}/comments'),
      );
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        _comments = list.reversed.toList();
      }
    } catch (_) {}
  }

  Future<void> _fetchLikeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final resp = await http.get(
        Uri.parse('http://localhost:8080/feeds/${widget.feedId}/like/status'),
        //Uri.parse('http://10.0.2.2:8080/feeds/${widget.feedId}/like/status'),
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
        Uri.parse('http://localhost:8080/feeds/${widget.feedId}/like'),
        //Uri.parse('http://10.0.2.2:8080/feeds/${widget.feedId}/like'),
        headers: {'Authorization': 'Bearer $token'},
      );
      await _fetchLikeStatus();
      setState(() {});
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
        Uri.parse('http://localhost:8080/feeds/${widget.feedId}/comments'),
        //Uri.parse('http://10.0.2.2:8080/feeds/${widget.feedId}/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': text}),
      );
      if (resp.statusCode == 201) {
        _commentController.clear();
        await _fetchComments();
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
    context.push('/feeds/${widget.feedId}/edit');
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
      Uri.parse('http://localhost:8080/feeds/${widget.feedId}'),
      //Uri.parse('http://10.0.2.2:8080/feeds/${widget.feedId}'),
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
        appBar: TopNavBar(onBack: () => context.pop()),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error || _feed == null) {
      return Scaffold(
        appBar: TopNavBar(onBack: () => context.pop()),
        body: const Center(child: Text('데이터를 불러올 수 없습니다.')),
      );
    }
    return Scaffold(
      appBar: TopNavBar(onBack: () => context.pop()),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 및 옵션
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _feed!['title'] ?? '',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_feed!['authorNickname']} | ${_formatDate(_feed!['createdAt'])}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                    _feed!['content'] ?? '',
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
                    ],
                  ),
                  const Divider(
                      color: Color(0xFF9CB4CD),
                      thickness: 3.0,
                      indent: 0,
                      endIndent: 0,
                  ),
                  // 댓글 리스트 또는 첫 번째 댓글 안내
                  if (_comments.isEmpty)
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
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) =>  const Divider(
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
            ),
          ),
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
            ),
          ),
        ],
      ),
    );
  }
}
