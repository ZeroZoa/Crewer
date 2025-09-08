import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http; // HTTP 요청
import 'dart:convert'; // JSON 변환
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:client/components/login_modal_screen.dart'; // 로그인 모달
import '../components/custom_app_bar.dart';
import '../config/api_config.dart';

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
  bool _loading = true;
  bool _error = false;
  bool _isLiked = false;

  final TextEditingController _commentController = TextEditingController();
  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.feeds}/${widget.feedId}'),
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
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.feeds}/${widget.feedId}/comments'),
      );
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        _comments = list.reversed.toList();
      }
    } catch (_) {}
  }

  Future<void> _fetchLikeStatus() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) return;
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.feeds}/${widget.feedId}/like/status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        _isLiked = json.decode(resp.body) as bool;
      }
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      _showLoginModal();
      return;
    }
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.feeds}/${widget.feedId}/like'),
        headers: {'Authorization': 'Bearer $token'},
      );
      await _fetchLikeStatus();
      setState(() {});
    } catch (_) {}
  }

  Future<void> _handleCommentSubmit() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      _showLoginModal();
      return;
    }
    try {
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.feeds}/${widget.feedId}/comments'),
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
    final token = await _storage.read(key: _tokenKey);

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
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      _showLoginModal();
      return;
    }

    // 3) 실제 삭제 요청
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.feeds}/${widget.feedId}'),
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
    if (_error || _feed == null) {
      return Scaffold(
        body: const Center(child: Text('데이터를 불러올 수 없습니다.')),
      );
    }
    return Scaffold(
      appBar: CustomAppBar(
        appBarType: AppBarType.back,
        title: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 0, top: 4),
          child: Text(''),
        ),
        actions: [ PopupMenuButton<String>(
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
                      ),],
      ),
      backgroundColor: Color(0xFFFAFAFA),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                                  radius: 25,
                                  backgroundImage: null,
                                ),
                      SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                                  onTap: () async {
                                    // 작성자의 프로필로 이동
                                    final authorUsername = _feed!['authorUsername'];
                                    if (authorUsername != null) {
                                      // 내 username인지 확인
                                      final token = await _storage.read(key: _tokenKey);
                                      if (token != null) {
                                        try {
                                          final profileResponse = await http.get(
                                            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfileMe()}'),
                                            headers: {'Authorization': 'Bearer $token'},
                                          );
                                          if (profileResponse.statusCode == 200) {
                                            final profile = json.decode(profileResponse.body);
                                            final currentUsername = profile['username'];
                                            
                                            if (authorUsername == currentUsername) {
                                              // 내 프로필인 경우
                                              context.push('/profile');
                                            } else {
                                              // 다른 사용자 프로필인 경우
                                              context.push('/user/$authorUsername');
                                            }
                                          } else {
                                            // 프로필 정보를 가져올 수 없는 경우 기본 동작
                                            context.push('/user/$authorUsername');
                                          }
                                        } catch (e) {
                                          // 에러 발생 시 기본 동작
                                          context.push('/user/$authorUsername');
                                        }
                                      } else {
                                        // 로그인되지 않은 경우 기본 동작
                                        context.push('/user/$authorUsername');
                                      }
                                    }
                                  },
                                  child: Text(
                                    _feed!['authorNickname'] ?? '',
                                    style: TextStyle(
                                      color: Colors.black, 
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_formatDate(_feed!['createdAt'])}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                        ],
                      ),
                      Spacer(),
                       IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : LucideIcons.heart,
                          color: _isLiked? const Color(0xFFFF002B): const Color(0xFF000000),
                        ),
                        iconSize: 28,
                        onPressed: _toggleLike,
                      ),
                  ],
                  ),
                  // 제목
                  Text(
                    _feed!['title'] ?? '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10), // 세로 여백
                  // 본문
                  Text(
                    _feed!['content'] ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  // 좋아요 버튼과 댓글 수
                  //     Text(
                  //       '댓글 ${_comments.length}',
                  //       style: const TextStyle(color: Colors.black, fontSize: 16),
                  //     ),

                  Row(
                      children: [ Icon(LucideIcons.heart,
                                color: Color(0xFFFF002B), size: 17),
                            SizedBox(width: 2),
                            Text('0'),
                            SizedBox(width: 10),
                            Icon(LucideIcons.messageCircle,
                                color: Colors.grey, size: 17),
                            SizedBox(width: 3),
                            Text('0'),],
                    ),
                  const Divider(
                      color: Color(0xFFDBDBDB),
                      thickness: 1.0,
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
                          Icon(LucideIcons.laugh, size: 70, color: Color(0xFF767676)),
                          const SizedBox(height: 16),
                          const Text(
                            '첫 번째 댓글을 남겨주세요!',
                            style: TextStyle(
                              color: Color(0xFFBDBDBD),
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
