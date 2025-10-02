import 'package:client/components/feed_option_modal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:client/components/login_modal_screen.dart';
import '../components/custom_app_bar.dart';
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
  bool _loading = true;
  String? _errorMessage;

  final TextEditingController _commentController = TextEditingController();
  String? _currentUsername;

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

  Future<void> _initializeAndFetchData() async {
    await _getCurrentUsername();
    await _fetchGroupFeedData();
  }

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



  Future<void> _fetchGroupFeedData() async {
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
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedDetail(widget.groupFeedId)}'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {

        setState(() {
          _groupFeed = json.decode(utf8.decode(response.bodyBytes));
          _loading = false;
        });
      } else {
        if (mounted) {
          final newToken = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            builder: (_) => LoginModalScreen(),
          );

          if (newToken != null) {
            await _fetchGroupFeedData();
          } else {
            if (mounted) context.pop();
          }
        }
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

  Future<void> _toggleLike() async {
    final token = await _storage.read(key: 'token');

    if (token == null) {
      _showLoginModal();
      return;
    }

    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedLike(widget.groupFeedId)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      await _fetchGroupFeedData();
    } catch (_) {}
  }

  Future<void> _handleCommentSubmit() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final token = await _storage.read(key: 'token');
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
        _commentController.clear();
        FocusScope.of(context).unfocus(); // 키보드 숨기기
        await _fetchGroupFeedData(); // 전체 데이터 리프레시
      }
    } catch (_) {
      // 에러 처리
    }
  }

  Future<void> _toggleParticipation() async {
    final token = await _storage.read(key: _tokenKey);

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



  // 수정: 로그인 체크 후 이동
  Future<void> _handleEdit() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      _showLoginModal();
      return;
    }
    context.push('/groupfeeds/${widget.groupFeedId}/edit');
  }

  void _handleProfileTap(String authorUsername) {
    if (_currentUsername == authorUsername) {
      context.push('/profile');
    } else {
      context.push('/user/$authorUsername');
    }
  }

  // Future<void> _handleDelete() async {
  //   // 삭제 확인 다이얼로그
  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text('삭제 확인'),
  //       content: const Text('정말 삭제하시겠습니까?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => context.pop(false),
  //           child: const Text('취소'),
  //         ),
  //         TextButton(
  //           onPressed: () => context.pop(true),
  //           child: const Text('삭제', style: TextStyle(color: Colors.red)),
  //         ),
  //       ],
  //     ),
  //   );
  //   if (confirm != true) return;

  //   // 로그인 체크
  //   final token = await _storage.read(key: _tokenKey);

  //   if (token == null) {
  //     _showLoginModal();
  //     return;
  //   }

  //   // 실제 삭제 요청
  //   await http.delete(
  //     Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedDetail(widget.groupFeedId)}'),
  //     headers: {'Authorization': 'Bearer $token'},
  //   );
  //   context.replace('/');
  // }

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginModalScreen(),
    ).then((_) => _initializeAndFetchData());
  }
    void _showOptionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FeedOptionModalScreen(feedId : widget.groupFeedId, isFeed: false,),
    );
  }


  //그룹피드 작성시간 변환 매서드
  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    return d.toLocal().toString().substring(0, 19);
  }

  //크루 모집 마감시간 변환 매서드
  String _formatDeadline(String? iso) {
    if(iso == null || iso.isEmpty){
      return "";
    }else{
      final parsedDate = DateTime.parse(iso);
      final formattedDate = DateFormat('yyyy년 MM월 dd일 HH시 mm분').format(parsedDate);

      return formattedDate;
    }
  }

  String _formatRemainingTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return '마감 정보 없음';
    }

    final deadline = DateTime.parse(isoString);
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return '마감됨';
    }

    // 남은 시간이 1시간 이상일 경우
    if (difference.inHours >= 1) {
      final days = difference.inDays;
      final hours = difference.inHours % 24;

      // 수정: days가 0보다 클 때만 '일'을 표시하도록 변경
      if (days > 0) {
        return '마감까지 ${days}일 ${hours.toString().padLeft(2, '0')}시간!';
      } else {
        // days가 0이면 '시간'만 표시
        return '마감까지 ${hours.toString().padLeft(2, '0')}시간!';
      }
    }
    // 남은 시간이 1시간 미만, 1분 이상일 경우
    else if (difference.inMinutes >= 1) {
      return '마감까지 ${difference.inMinutes}분!';
    }
    // 남은 시간이 1분 미만일 경우
    else {
      return '곧 마감이에요';
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_groupFeed == null) {
      return Scaffold(
        body: const Center(child: Text('데이터를 불러올 수 없습니다.')),
      );
    }

    final groupFeedData = _groupFeed!;
    final comments = (groupFeedData['comments'] as List).reversed.toList();
    final isLiked = groupFeedData['isLiked'] ?? false;
    final likeCount = groupFeedData['likesCount'];
    final commentCount = groupFeedData['commentsCount'];
    final authorUsername = groupFeedData['authorUsername'] ?? '';
    final authorNickname = groupFeedData['authorNickname'] ?? '';

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        appBarType: AppBarType.back,
        title: Padding(
          padding: const EdgeInsets.only(left: 0, bottom: 3),
          child: Text(
            '그룹피드',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18.0,
            ),
          ),
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
            child : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 6),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.grey[300],
                                        backgroundImage: _groupFeed!['authorAvatarUrl'] != null
                                            ? NetworkImage(_groupFeed!['authorAvatarUrl'].startsWith('http') 
                                                ? _groupFeed!['authorAvatarUrl'] 
                                                : '${ApiConfig.baseUrl}${_groupFeed!['authorAvatarUrl']}')
                                            : null,
                                        child: _groupFeed!['authorAvatarUrl'] == null
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
                                            _formatDate(_groupFeed!['createdAt']),
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
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16,),
                                  Text(
                                    _groupFeed!['title'] ?? '',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  // 본문
                                  Text(
                                    _groupFeed!['content'] ?? '',
                                    style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF535353)),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16), // 수정: 모든 방향에 일관된 여백 적용
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, // 수정: 자식들을 왼쪽 정렬
                                      children: [
                                        // 1. 장소 정보
                                        Row(
                                          children: [
                                            Icon(LucideIcons.mapPin, size: 18.0, color: Colors.black),
                                            const SizedBox(width: 6),
                                            Text(
                                              _groupFeed!['meetingPlace'].length > 10
                                                  ? '${_groupFeed!['meetingPlace'].substring(0, 10)}...'
                                                  : _groupFeed!['meetingPlace']
                                              ,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                                            ),
                                            const Spacer(),
                                            Text(
                                              _formatRemainingTime(_groupFeed!['deadline'] as String?),
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.bold
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // 3. 참여 현황 바 추가
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: LinearProgressIndicator(
                                                value: (_groupFeed!['maxParticipants'] != null && _groupFeed!['maxParticipants'] > 0)
                                                    ? (_groupFeed!['currentParticipants'] ?? 0) / _groupFeed!['maxParticipants']
                                                    : 0.0,
                                                minHeight: 8,
                                                backgroundColor: Colors.grey[200],
                                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF002B)),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '${_groupFeed!['currentParticipants'] ?? 0}명 모집완료',
                                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                                                ),
                                                Text(
                                                  '모집인원: ${_groupFeed!['maxParticipants'] ?? 0}',
                                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: _toggleParticipation,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFF002B),
                                              foregroundColor: Colors.white,
                                              // 수정: vertical padding 값을 16에서 8로 줄여 버튼의 높이를 낮춥니다.
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(24),
                                              ),
                                            ),
                                            child: const Text(
                                              'Crew 참여하기',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const SizedBox(width: 4),
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
                  if(comments.isEmpty)
                    Center(
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
                                TextSpan(text: _formatDate(c['createdAt'])),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const Divider(color: Color(0xFFECECEC));
                      },
                    ),
                ],
              ),
            )
          ),
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
