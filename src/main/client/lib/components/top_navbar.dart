// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:lucide_icons/lucide_icons.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart'; // AuthProvider import
// import 'login_modal_screen.dart';
//
// /// 상단 네비게이션 바 컴포넌트
// // 수정된 부분: 자체 상태를 관리하지 않으므로 StatelessWidget으로 변경했습니다.
// class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
//   final VoidCallback onBack;
//
//   const TopNavBar({
//     Key? key,
//     required this.onBack,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final bool canPop = context.canPop();
//
//     return AppBar(
//       backgroundColor: Colors.white,
//       elevation: 0,
//       leading: canPop
//           ? IconButton(
//         icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF9CB4CD)),
//         // 수정된 부분: StatelessWidget에서는 'widget.' 접두사 없이 속성에 접근합니다.
//         onPressed: onBack,
//       )
//           : null,
//       title: GestureDetector(
//         onTap: () {
//           if (canPop) {
//             // 수정된 부분: 여기도 마찬가지로 'widget.'을 제거합니다.
//             onBack();
//           } else {
//             context.go('/');
//           }
//         },
//         child: const Text(
//           'Crewer',
//           style: TextStyle(
//             fontFamily: 'CustomFont',
//             color: Color(0xFF9CB4CD),
//             fontSize: 36,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       centerTitle: true,
//       // 수정된 부분: actions 부분을 Consumer 위젯으로 감싸서 AuthProvider의 상태 변화를 감지합니다.
//       actions: [
//         Consumer<AuthProvider>(
//           builder: (context, authProvider, child) {
//             // authProvider의 isLoggedIn 상태를 '지켜보고' 있다가,
//             // 상태가 바뀌면 이 builder 부분이 자동으로 다시 실행됩니다.
//             if (authProvider.isLoggedIn) {
//               // 로그인 상태일 때 보여줄 위젯 (예: 프로필 아이콘)
//               return IconButton(
//                 icon: const Icon(LucideIcons.userCircle2, color: Color(0xFF9CB4CD)),
//                 onPressed: () {
//                   context.push('/profile');
//                 },
//               );
//             } else {
//               // 로그아웃 상태일 때 보여줄 위젯
//               return IconButton(
//                 icon: const Icon(LucideIcons.logIn, color: Color(0xFF9CB4CD)),
//                 onPressed: () {
//                   showModalBottomSheet(
//                     context: context,
//                     isScrollControlled: true,
//                     builder: (_) => LoginModalScreen(),
//                   );
//                   // 모달이 닫힌 후의 상태 업데이트는 AuthProvider가 자동으로 처리하므로
//                   // .then() 블록은 더 이상 필요 없습니다.
//                 },
//               );
//             }
//           },
//         ),
//       ],
//       bottom: const PreferredSize(
//         preferredSize: Size.fromHeight(1),
//         child: Divider(
//           height: 1,
//           thickness: 1,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Size get preferredSize => Size.fromHeight(56);
// }