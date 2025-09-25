import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http; // HTTP 요청
import 'dart:convert'; // JSON 변환
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:client/components/login_modal_screen.dart'; // 로그인 모달
import 'package:client/components/feed_option_modal_screen.dart'; // 옵션 모달
import '../components/custom_app_bar.dart';
import '../config/api_config.dart';

/// 피드 상세 화면
/// feedId에 해당하는 모든 정보를 서버에서 한 번에 가져와 렌더링합니다.
class FeedDetailScreen extends StatefulWidget {
  final String feedId;
  const FeedDetailScreen({Key? key, required this.feedId}) : super(key: key);

  @override
  _FeedDetailScreenState createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  // 수정: 모든 피드 관련 데이터를 이 Map 하나로 관리합니다.
  Map<String, dynamic>? _feed;
  bool _loading = true;
  String? _errorMessage;

  final TextEditingController _commentController = TextEditingController();
  String? _currentUsername; // 수정: 현재 사용자 username 캐싱

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initializeAndFetchData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 수정: 화면 진입 시 사용자 정보와 피드 데이터를 순차적으로 로드
  Future<void> _initializeAndFetchData() async {
    await _getCurrentUsername();
    await _fetchFeedData();
  }

  // 수정: 현재 로그인된 사용자의 username을 미리 캐싱하여 불필요한 API 호출 방지
  Future<void> _getCurrentUsername() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfileMe()}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final profile = json.decode(utf8.decode(response.bodyBytes));
        _currentUsername = profile['username'];
      }
    } catch (_) {}
  }

  // 수정: 모든 데이터를 한 번에 가져오는 통합 메소드
  Future<void> _fetchFeedData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'token');
      final headers = <String, String>{};
      // 로그인 상태이면 토큰을 포함하여 'isLiked' 여부를 정확히 받아옴
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.feeds}/${widget.feedId}'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {

        setState(() {
          _feed = json.decode(utf8.decode(response.bodyBytes));
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = '피드를 불러오는 데 실패했습니다. (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다.';
        _loading = false;
      });
    }
  }

  // 수정: 좋아요 토글 후 전체 데이터를 다시 불러와 상태를 완벽하게 동기화
  Future<void> _toggleLike() async {
    final token = await _storage.read(key: 'token');

    if (token == null) {
      _showLoginModal();
      return;
    }

    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getFeedLike(widget.feedId)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      await _fetchFeedData(); // 서버의 최신 상태로 전체 데이터를 다시 로드
    } catch (_) {
      // 에러 처리
    }
  }

  // 수정: 댓글 작성 후 전체 데이터를 다시 불러옴
  Future<void> _handleCommentSubmit() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final token = await _storage.read(key: 'token');
    if (token == null) {
      _showLoginModal();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getFeedComments(widget.feedId)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': text}),
      );

      if (response.statusCode == 201) {
        _commentController.clear();
        FocusScope.of(context).unfocus(); // 키보드 숨기기
        await _fetchFeedData(); // 전체 데이터 리프레시
      }
    } catch (_) {
      // 에러 처리
    }
  }

  void _handleProfileTap(String authorUsername) {
    if (_currentUsername == authorUsername) {
      context.push('/profile');
    } else {
      context.push('/user/$authorUsername');
    }
  }


  String _formatDateAgo(String isoString) {
    final date = DateTime.parse(isoString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 30) {
      return '방금';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else {
      return '${difference.inDays}일 전';
    }
  }

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginModalScreen(),
    ).then((_) => _fetchFeedData()); // 수정: 로그인 후 전체 데이터 리프레시
  }

    void _showOptionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FeedOptionModalScreen(feedId : widget.feedId, isFeed: true,),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    return d.toLocal().toString().substring(0, 19);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null || _feed == null) {
      return Scaffold(body: Center(child: Text(_errorMessage ?? '데이터를 불러올 수 없습니다.')));
    }

    final feedData = _feed!;
    final comments = (feedData['comments'] as List).reversed.toList();
    final isLiked = feedData['isLiked'] ?? false;
    final likeCount = feedData['likeCount'];
    final commentCount = feedData['commentCount'];
    final authorUsername = feedData['authorUsername'] ?? '';
    final authorNickname = feedData['authorNickname'] ?? '';

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        appBarType: AppBarType.back,
        title: const Padding(
          padding: EdgeInsets.only(left: 0, bottom: 3),
          child: Text('피드', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.0)),
        ),
        actions: [
          if (_currentUsername == authorUsername)
            TextButton(
              child: const Icon(LucideIcons.moreVertical,
              color: Color(0xFF767676),
              size: 23,),
              onPressed: (){
                _showOptionModal();
              },   
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: feedData['authorAvatarUrl'] != null
                                  ? NetworkImage(feedData['authorAvatarUrl'].startsWith('http') 
                                      ? feedData['authorAvatarUrl'] 
                                      : '${ApiConfig.baseUrl}${feedData['authorAvatarUrl']}')
                                  : null,
                              child: feedData['authorAvatarUrl'] == null
                                  ? Icon(Icons.person, size: 25, color: Colors.grey[600])
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => _handleProfileTap(authorUsername),
                                  child: Text(
                                    authorNickname,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 2,),
                                Text(
                                  _formatDate(feedData['createdAt']),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _toggleLike,
                              iconSize: 28,
                              icon: Icon(
                                isLiked ? Icons.favorite : LucideIcons.heart,
                                color: isLiked ? Colors.red : Colors.black,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          feedData['title'] ?? '',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          feedData['content'] ?? '',
                          style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF535353)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(LucideIcons.heart, color: Color(0xFFFF002B), size: 17),
                            const SizedBox(width: 3),
                            Text('$likeCount'),

                            const SizedBox(width: 10),

                            const Icon(LucideIcons.messageCircle, color: Colors.grey, size: 17),
                            const SizedBox(width: 3),
                            Text('$commentCount'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFDBDBDB), thickness: 1.0),
                  // 댓글 목록 UI
                  if (comments.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            const Icon(LucideIcons.messageCircle, color: Colors.grey, size: 100),
                            const SizedBox(height: 8),
                            Text('첫 번째 댓글을 남겨주세요!', style: TextStyle(color: Colors.grey, fontSize: 20)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return ListTile(
                          title: Text(c['content'] ?? '', style: const TextStyle(fontSize: 16.0),),
                          subtitle: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                              children: [
                                // 첫 번째 부분: 닉네임
                                TextSpan(
                                  text: '${c['authorNickname'] ?? '익명'}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),

                                // 수정: 공백을 가진 TextSpan을 추가하여 간격을 줍니다.
                                const TextSpan(text: '  '), // 원하는 만큼 공백을 추가

                                // 두 번째 부분: 시간
                                TextSpan(text: _formatDateAgo(c['createdAt'])),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const Divider(color: Color(0xFFECECEC));
                      },
                    )
                ],
              ),
            ),
          ),
          // 댓글 입력창
          SafeArea(
            child: Container(
              // 수정: height 속성을 추가하여 높이를 직접 지정 (기존 약 75에서 15% 정도 줄임)
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                color: Colors.white,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Row 아이템들을 중앙 정렬
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: '댓글을 입력하세요',
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
                    // 수정: 너비와 높이를 지정하여 버튼의 전체 크기를 줄입니다.
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(left: 8.0), // TextField와의 간격
                    decoration: const BoxDecoration(
                      color: Colors.red,       // 배경색을 빨간색으로
                      shape: BoxShape.circle,  // 모양을 동그랗게
                    ),
                    child: IconButton(
                      // 수정: 아이콘 버튼의 기본 내부 여백을 제거하여 아이콘이 중앙에 오도록 합니다.
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        LucideIcons.send,
                        color: Colors.white,
                        size: 20, // 수정: 버튼 크기에 맞춰 아이콘 크기도 약간 줄입니다.
                      ),
                      onPressed: _handleCommentSubmit,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
