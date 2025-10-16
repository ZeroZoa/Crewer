import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 1. enum 정의
enum AppBarType {
  main,        // 메인 화면용: 검색 + 알림 아이콘
  back,        // 뒤로가기 + 검색 + 알림 아이콘
  close,       // 닫기 버튼만 (모달용)
  backOnly,    // 뒤로가기 버튼만
  settings,    // 설정 아이콘만 (오른쪽)
  backWithMore, // 뒤로가기 + 더보기 아이콘
  none,        // AppBar 숨김 (투명)
}

// 알림 뱃지가 있는 아이콘 위젯
class NotificationIconWithBadge extends StatefulWidget {
  final VoidCallback? onPressed;
  
  const NotificationIconWithBadge({Key? key, this.onPressed}) : super(key: key);
  
  @override
  _NotificationIconWithBadgeState createState() => _NotificationIconWithBadgeState();
}

class _NotificationIconWithBadgeState extends State<NotificationIconWithBadge> {
  int _unreadCount = 0;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
  }
  
  Future<void> _loadNotificationCount() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getNotificationCount()}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _unreadCount = data['unreadCount'] ?? 0;
        });
      }
    } catch (e) {
      // 오류 시 무시
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: widget.onPressed,
          icon: const Icon(Icons.notifications_outlined),
          color: const Color(0xFF767676),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final AppBarType appBarType;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onMainSearchPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onBackPressed;
  final VoidCallback? onEndMeetingPressed;
  final VoidCallback? onLeaveChatPressed;

  const CustomAppBar({
    super.key,
    required this.appBarType,
    this.title,
    this.leading,
    this.actions,
    this.onSearchPressed,
    this.onMainSearchPressed,
    this.onNotificationPressed,
    this.onBackPressed,
    this.onEndMeetingPressed,
    this.onLeaveChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    // none 타입일 경우, 아무것도 보이지 않는 투명한 AppBar를 반환
    if (appBarType == AppBarType.none) {
      return const SizedBox.shrink();
    }

    return AppBar(
      // AppBar의 기본 스타일링
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0.5,
      centerTitle: appBarType != AppBarType.main,
      leadingWidth: appBarType == AppBarType.settings ? 0 : (appBarType == AppBarType.close ? 60 : 120),
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,

      titleSpacing: appBarType == AppBarType.main ? 0.0 : NavigationToolbar.kMiddleSpacing,
      // leading이 직접 전달되면 그것을 사용, 아니면 타입에 따라 결정
      leading: leading ?? _buildLeading(context),
      // title이 직접 전달되면 그것을 사용, 아니면 타입에 따라 결정
      title: title ?? _buildTitle(),
      // actions가 직접 전달되면 그것을 사용, 아니면 타입에 따라 결정
      actions: actions ?? _buildActions(context),
    );
  }

  // 타입에 따라 기본 Leading 위젯을 생성하는 함수
  Widget? _buildLeading(BuildContext context) {
    switch (appBarType) {
      case AppBarType.main:
        return null;
      case AppBarType.back:
        return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.only(left: 6),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 24, color: Color(0xFF767676)),
              onPressed: onBackPressed ?? () => context.pop(),
              )
            ]
        );
      case AppBarType.close:
        return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.only(left: 6),
                icon: const Icon(Icons.close, size: 30, color: Color(0xFF767676)),
                onPressed: onBackPressed ?? () => context.pop(),
              )
            ]
        );
      case AppBarType.backOnly:
        return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.only(left: 6),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 24, color: Color(0xFF767676)),
                onPressed: onBackPressed ?? () => context.pop(),
              )
            ]
        );
      case AppBarType.settings:
        return SizedBox.shrink();
      case AppBarType.backWithMore:
        return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.only(left: 6),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 24, color: Color(0xFF767676)),
                onPressed: onBackPressed ?? () => context.pop(),
              ),
            ]
        );
      case AppBarType.none:
        return null;
    }
  }

  // 타입에 따라 기본 Title 위젯을 생성하는 함수
  Widget? _buildTitle() {
    if (appBarType == AppBarType.main) {
    }
    // 다른 타입들은 기본 title이 없으므로 null 반환 (사용자가 직접 title 위젯을 전달해야 함)
    return null;
  }

  // 타입에 따라 기본 Actions 리스트를 생성하는 함수
  List<Widget>? _buildActions(BuildContext context) {
    switch (appBarType) {
      case AppBarType.main:
        return [
          IconButton(
            icon: const Icon(Icons.search, size: 27, color: Color(0xFF767676)),
            onPressed: onMainSearchPressed,
          ),
          NotificationIconWithBadge(
            onPressed: onNotificationPressed,
          ),
          const SizedBox(width: 8),
        ];
      case AppBarType.back:
        return [
          IconButton(
            icon: const Icon(Icons.search, size: 29, color: Color(0xFF767676)),
            onPressed: onSearchPressed,
          ),
          NotificationIconWithBadge(
            onPressed: onNotificationPressed,
          ),
          const SizedBox(width: 8),
        ];
      case AppBarType.settings:
        return [
          IconButton(
            icon: const Icon(Icons.settings, size: 24, color: Color(0xFF767676)),
            onPressed: onSearchPressed, // 설정 버튼 클릭 시 호출될 콜백
          ),
          const SizedBox(width: 8),
        ];
      case AppBarType.backWithMore:
        return [
          IconButton(
            icon: const Icon(Icons.more_vert, size: 24, color: Color(0xFF767676)),
            onPressed: onSearchPressed, // 일반 더보기 버튼
          ),
          const SizedBox(width: 8),
        ];
      case AppBarType.close:
      case AppBarType.backOnly:
      case AppBarType.none:
        return null;
    }
  }

  // AppBar의 높이를 지정
  @override
  Size get preferredSize {
    // none 타입일 경우 높이를 0으로 만들어 완전히 사라지게 함

    return appBarType == AppBarType.none
        ? Size.zero
        : const Size.fromHeight(kToolbarHeight);
  }

}