// lib/components/common_app_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 1. enum 정의
enum LeadingIconType {
  back,
  close,
  none,
}

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  // 2. bool 타입 대신 enum 타입으로 변경
  final LeadingIconType leadingType;
  final Widget? leading;
  final List<Widget>? actions;
  final Color backgroundColor;
  final double elevation;

  const CommonAppBar({
    super.key,
    this.title,
    // 3. 기본값은 뒤로가기 버튼으로 설정
    this.leadingType = LeadingIconType.back,
    this.leading,
    this.actions,
    this.backgroundColor = Colors.white,
    this.elevation = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading ?? _buildLeadingIcon(context),
      title: title,
      actions: actions,
      backgroundColor: backgroundColor,
      elevation: elevation,
      centerTitle: true,
      foregroundColor: Colors.black,
    );
  }

  // 5. leadingType 값에 따라 다른 아이콘 버튼을 반환하는 헬퍼(helper) 메서드
  Widget? _buildLeadingIcon(BuildContext context) {
    switch (leadingType) {
      case LeadingIconType.back:
        return IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        );
      case LeadingIconType.close:
        return IconButton(
          icon: Icon(Icons.close),
          onPressed: () => context.pop(),
        );
      case LeadingIconType.none:
      // leading을 null로 설정하면 자동으로 공간이 사라짐
        return null;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}