import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../config/api_config.dart';
import '../components/custom_app_bar.dart';
import '../components/login_modal_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndLoad();
    });
  }

  /// 로그인 상태 확인 후 데이터 로드
  Future<void> _checkLoginAndLoad() async {
    final token = await _storage.read(key: 'token');
    
    if (token == null) {
      if (mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => LoginModalScreen(),
        );
        
        final newToken = await _storage.read(key: 'token');
        
        if (newToken == null) {
          if (mounted) context.pop();
        } else {
          await _loadNotifications();
        }
      }
    } else {
      await _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        if (mounted) {
          await _checkLoginAndLoad();
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notifications}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // 인증 실패 시 로그인 모달
        if (mounted) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => LoginModalScreen(),
          );
          
          final newToken = await _storage.read(key: 'token');
          
          if (newToken != null) {
            await _loadNotifications();
          } else {
            if (mounted) context.pop();
          }
        }
      } else {
        setState(() {
          _error = '알림을 불러올 수 없습니다';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '네트워크 오류가 발생했습니다';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notifications}/$notificationId/read'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['id'].toString() == notificationId);
          if (index != -1) {
            _notifications[index]['read'] = true;
          }
        });
      }
    } catch (e) {
      // 에러 발생 시 무시 (사용자 경험 방해 안 함)
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    // 알림을 읽음으로 표시
    if (!(notification['read'] ?? false)) {
      _markAsRead(notification['id'].toString());
    }

    // 알림 타입에 따라 다른 화면으로 이동
    switch (notification['type']) {
      case 'EVALUATION_REQUEST':
        // 평가 완료된 알림은 클릭 불가능
        final isEvaluationCompleted = notification['evaluationCompleted'] ?? false;
        if (isEvaluationCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 평가를 완료한 모임입니다')),
          );
          return;
        }
        // 평가 화면으로 이동하고 돌아올 때까지 대기
        await context.push('/evaluation/${notification['relatedGroupFeedId']}');
        // 평가 화면에서 돌아오면 알림 목록 새로고침
        await _loadNotifications();
        break;
      case 'GROUP_COMPLETED':
        // 모임 완료 알림은 단순히 읽음 처리만
        break;
      default:
        break;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'EVALUATION_REQUEST':
        return Icons.rate_review;
      case 'GROUP_COMPLETED':
        return Icons.event_available;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'EVALUATION_REQUEST':
        return '크루원 평가 요청';
      case 'GROUP_COMPLETED':
        return '모임이 완료되었습니다';
      default:
        return '알림';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        appBarType: AppBarType.backOnly,
        title: const Text(
          '알림',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final token = _storage.read(key: 'token');
                          token.then((token) {
                            if (token != null) {
                              _loadNotifications();
                            } else {
                              _checkLoginAndLoad();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9CB4CD),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '알림이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        final token = await _storage.read(key: 'token');
                        if (token != null) {
                          await _loadNotifications();
                        } else {
                          await _checkLoginAndLoad();
                        }
                      },
                      color: const Color(0xFF9CB4CD),
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _buildNotificationItem(notification);
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['read'] ?? false;
    final isEvaluationCompleted = notification['evaluationCompleted'] ?? false;
    final createdAt = DateTime.parse(notification['createdAt']);
    final timeAgo = _getTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isRead ? 1 : 3,
      color: isEvaluationCompleted ? Colors.grey[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isEvaluationCompleted ? BorderSide(color: Colors.grey[300]!, width: 1) : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEvaluationCompleted 
              ? Colors.grey[400] 
              : (isRead ? Colors.grey[300] : const Color(0xFFFF002B)),
          child: Icon(
            isEvaluationCompleted ? Icons.check_circle : _getNotificationIcon(notification['type']),
            color: isEvaluationCompleted 
                ? Colors.white 
                : (isRead ? Colors.grey[600] : Colors.white),
            size: 20,
          ),
        ),
        title: Text(
          isEvaluationCompleted 
              ? '${_getNotificationTitle(notification['type'])} (완료)'
              : _getNotificationTitle(notification['type']),
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: isEvaluationCompleted 
                ? Colors.grey[500] 
                : (isRead ? Colors.grey[600] : Colors.black87),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              isEvaluationCompleted 
                  ? '이미 평가를 완료한 모임입니다'
                  : (notification['content'] ?? ''),
              style: TextStyle(
                color: isEvaluationCompleted 
                    ? Colors.grey[400] 
                    : (isRead ? Colors.grey[500] : Colors.grey[700]),
                fontStyle: isEvaluationCompleted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: isEvaluationCompleted 
                    ? Colors.grey[300] 
                    : Colors.grey[400],
              ),
            ),
          ],
        ),
        trailing: isEvaluationCompleted
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '완료',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : (!isRead
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF002B),
                      shape: BoxShape.circle,
                    ),
                  )
                : null),
        onTap: () async => await _handleNotificationTap(notification),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
