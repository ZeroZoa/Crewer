import 'package:client/components/custom_app_bar.dart';
import 'package:client/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/bottom_navbar.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// Screens
import 'package:client/screens/feed_list_screen.dart';
import 'package:client/screens/feed_create_screen.dart';
import 'package:client/screens/feed_edit_screen.dart';
import 'package:client/screens/feed_detail_screen.dart';
import 'package:client/screens/group_feed_create_screen.dart';
import 'package:client/screens/group_feed_edit_screen.dart';
import 'package:client/screens/group_feed_detail_screen.dart';
import 'package:client/screens/map_screen.dart';
import 'package:client/screens/my_profile_screen.dart';
import 'package:client/screens/user_profile_screen.dart';
import 'package:client/screens/user_feed_screen.dart';
import 'package:client/screens/signup_screen.dart';
import 'package:client/screens/chatroom_list_screen.dart';
import 'package:client/screens/chatroom_screen.dart';
import 'package:client/screens/ranking_screen.dart';
import 'package:client/components/login_modal_screen.dart';
import 'package:client/screens/my_feed_screen.dart';
import 'package:client/screens/my_liked_feed_screen.dart';
import 'package:client/screens/running_route_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:client/screens/follow_list_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider()..checkLoginStatus(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            final location = state.uri.toString();

            // // --- 📌 상단바(AppBar) 표시 로직 ---
            //
            // // '메인' 화면인지 확인
            // final mainRoutes = ['/', '/map', '/ranking'];
            //
            // // 현재 경로가 위 목록에 포함되는지 확인하여 '메인' 화면 여부를 결정합니다.
            // final isMain = mainRoutes.contains(location);
            //
            // // 자체 AppBar를 가진 화면들 (이 경우 Shell의 AppBar는 보이지 않음)
            // final selfAppBarRoutes = [
            //   '/feeds/create', '/groupfeeds/create', '/feeds/', '/groupfeeds/',
            //   '/signup', '/login', '/chat', '/route', '/profile', '/map',
            //   '/ranking', '/me/', '/user/',
            // ];
            //
            // // 3. Shell의 기본 AppBar를 보여줄지 결정 (간단한 페이지용)
            // final showShellAppBar = !isMain && !selfAppBarRoutes.any((path) => location.startsWith(path));
            //
            // // 4. Shell이 AppBar를 그려야 할 경우, 타입 결정
            // final appBarType = isMain ? AppBarType.main : AppBarType.back;


            // --- 📌 하단바(BottomNavBar) 표시 로직 (AppBar와 완전히 분리) ---

            // 1. 하단바가 '무조건' 보여야 하는 경로 목록
            final bottomNavRoutes = ['/', '/map', '/ranking', '/chat', '/profile'];

            // 2. 현재 경로가 위 목록에 정확히 일치하는지 확인
            final showBottomNav = bottomNavRoutes.contains(location);


            return Scaffold(
              backgroundColor: Colors.white,
              // isMain이거나 showShellAppBar가 true일 때만 Shell의 AppBar를 그림
              // appBar: (isMain || showShellAppBar) ? CustomAppBar(appBarType: appBarType) : null,
              // // showBottomNav가 true일 때만 하단바를 보임
              bottomNavigationBar: showBottomNav
                  ? BottomNavBar(currentLocation: location)
                  : null,
              body: child,
            );
          },
          routes: [
            // --- 화면 경로 목록 ---
            GoRoute(path: '/', builder: (_, __) =>  FeedListScreen()),
            GoRoute(path: '/signup', builder: (_, __) =>  SignupScreen()),
            GoRoute(path: '/login', builder: (_, __) =>  LoginModalScreen()),
            GoRoute(path: '/profile', builder: (_, __) =>  MyProfileScreen()),
            GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
            GoRoute(path: '/chat', builder: (_, __) => const ChatRoomListScreen()),
            GoRoute(path: '/ranking', builder: (_, __) => const RankingScreen()),
            GoRoute(
              path: '/chat/:chatRoomId',
              builder: (_, state) =>
                  ChatRoomScreen(
                    chatRoomId: state.pathParameters['chatRoomId']!,
                  ),
            ),
            GoRoute(
              path: '/feeds/create',
              builder: (_, __) => const FeedCreateScreen(),
            ),
            GoRoute(
              path: '/groupfeeds/create',
              builder: (_, __) => const GroupFeedCreateScreen(),
            ),
            GoRoute(
              path: '/feeds/:feedId',
              builder: (_, state) =>
                  FeedDetailScreen(feedId: state.pathParameters['feedId']!),
            ),
            GoRoute(
              path: '/feeds/:feedId/edit',
              builder: (_, state) =>
                  FeedEditScreen(feedId: state.pathParameters['feedId']!),
            ),
            GoRoute(
              path: '/groupfeeds/:groupFeedId',
              builder: (_, state) =>
                  GroupFeedDetailScreen(
                    groupFeedId: state.pathParameters['groupFeedId']!,
                  ),
            ),
            GoRoute(
              path: '/groupfeeds/:groupFeedId/edit',
              builder: (_, state) =>
                  GroupFeedEditScreen(
                    groupFeedId: state.pathParameters['groupFeedId']!,
                  ),
            ),
            GoRoute(
              path: '/me/feeds',
              builder: (context, state) => const MyFeedScreen(),
            ),
            GoRoute(
              path: '/me/liked-feeds',
              builder: (context, state) => const MyLikedFeedScreen(),
            ),
            GoRoute(
              path: '/me/followers',
              builder: (_, state) =>
              const FollowListScreen(
                username: 'me',
                isFollowers: true,
              ),
            ),
            GoRoute(
              path: '/me/following',
              builder: (_, state) =>
              const FollowListScreen(
                username: 'me',
                isFollowers: false,
              ),
            ),
            GoRoute(
              path: '/user/:username',
              builder: (_, state) =>
                  UserProfileScreen(
                    username: state.pathParameters['username']!,
                  ),
            ),
            GoRoute(
              path: '/user/:username/feeds',
              builder: (_, state) =>
                  UserFeedScreen(
                    username: state.pathParameters['username']!,
                  ),
            ),
            GoRoute(
              path: '/user/:username/followers',
              builder: (_, state) =>
                  FollowListScreen(
                    username: state.pathParameters['username']!,
                    isFollowers: true,
                  ),
            ),
            GoRoute(
              path: '/user/:username/following',
              builder: (_, state) =>
                  FollowListScreen(
                    username: state.pathParameters['username']!,
                    isFollowers: false,
                  ),
            ),
            GoRoute(
              path: '/route',
              builder: (context, state) {
                final record = state.extra as Map<String, dynamic>;
                final runningDate = DateFormat('yyyy년 M월 d일 \na h시 m분', 'ko_KR')
                    .format(DateTime.parse(record['createdAt'] as String).toLocal());
                final rawPath = record['path'] as List<dynamic>;
                final path = rawPath.map((p) =>
                    LatLng(p['latitude'] as double, p['longitude'] as double))
                    .toList();
                final distanceKm = (record['totalDistance'] as num) / 1000;
                final totalSeconds = record['totalSeconds'] as int;
                final totalTime = Duration(seconds: totalSeconds);
                final timeStr = [
                  totalTime.inHours.toString().padLeft(2, '0'),
                  (totalTime.inMinutes % 60).toString().padLeft(2, '0'),
                  (totalTime.inSeconds % 60).toString().padLeft(2, '0'),
                ].join(':');
                final paceSec = distanceKm > 0
                    ? (totalTime.inSeconds / distanceKm).round()
                    : 0;
                final pace = Duration(seconds: paceSec);
                final paceStr =
                    '${pace.inMinutes.toString().padLeft(2, '0')}:${(pace.inSeconds % 60).toString().padLeft(2, '0')}';

                return RouteScreen(
                  path: path,
                  distanceKm: distanceKm,
                  timeStr: timeStr,
                  paceStr: paceStr,
                  runningDateStr: runningDate,
                );
              },
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Crewer App',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF9CB4CD),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// main.dart

// import 'package:client/components/custom_app_bar.dart';
// import 'package:client/providers/auth_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:client/components/bottom_navbar.dart';
//
// // Screens import 생략 (기존처럼 유지)
// import 'package:client/screens/feed_list_screen.dart';
// import 'package:client/screens/feed_create_screen.dart';
// import 'package:client/screens/feed_edit_screen.dart';
// import 'package:client/screens/feed_detail_screen.dart';
// import 'package:client/screens/group_feed_create_screen.dart';
// import 'package:client/screens/group_feed_edit_screen.dart';
// import 'package:client/screens/group_feed_detail_screen.dart';
// import 'package:client/screens/map_screen.dart';
// import 'package:client/screens/my_profile_screen.dart';
// import 'package:client/screens/user_profile_screen.dart';
// import 'package:client/screens/user_feed_screen.dart';
// import 'package:client/screens/signup_screen.dart';
// import 'package:client/screens/chatroom_list_screen.dart';
// import 'package:client/screens/chatroom_screen.dart';
// import 'package:client/screens/ranking_screen.dart';
// import 'package:client/components/login_modal_screen.dart';
// import 'package:client/screens/my_feed_screen.dart';
// import 'package:client/screens/my_liked_feed_screen.dart';
// import 'package:client/screens/running_route_screen.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:client/screens/follow_list_screen.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/date_symbol_data_local.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // 한국어 날짜 포맷을 위한 초기화
//   await initializeDateFormatting('ko_KR');
//   runApp(
//     ChangeNotifierProvider(
//       create: (context) => AuthProvider()..checkLoginStatus(),
//       child: const MyApp(),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final GoRouter router = GoRouter(
//       initialLocation: '/',
//       routes: [
//         ShellRoute(
//           builder: (context, state, child) {
//             final location = state.uri.toString();
//
//             AppBarType appBarType;
//
//             final selfAppBarRoutes = [
//               '/feeds/',
//               '/groupfeeds/',
//               '/signup',
//               '/login',
//               '/chat/',
//               '/route',
//               '/profile',
//               '/map',
//               '/ranking',
//               '/me/', // '/me/feeds' 등 내 정보 관련 모든 페이지
//               '/user/', // '/user/username' 등 다른 유저 관련 모든 페이지
//             ];
//
//             final showShellAppBar = !selfAppBarRoutes.any((path) => location.startsWith(path));
//
//             // 메인 화면('/')일 경우
//             if (location == '/') {
//               appBarType = AppBarType.main;
//             }
//             // AppBar가 필요하고 닫기 화면들
//             else if (['/signup', '/login'].any((path) => location.startsWith(path))) {
//               appBarType = AppBarType.close;
//             }
//             // else if ([
//             //   '/feeds/', //피드(생성, 수정, 상세) 페이지
//             //   '/groupfeeds/', //그룹피드(생성, 수정, 상세) 페이지
//             //   '/chat', //채팅(리스트, 방) 페이지
//             //   '/route', //경로 페이지
//             //   '/map', //지도 페이지
//             //   '/ranking', //랭킹페이지
//             //   '/profile', //마이페이지
//             // ].any((path) => location.startsWith(path))) {
//             //   appBarType = AppBarType.back;
//             // }
//             // 4. 그 외 모든 화면은 없음
//             else {
//               appBarType = AppBarType.none;
//             };
//
//
//             // 하단바를 보여주지않는 화면들
//             final showBottomNav = ![
//               '/feeds/create',
//               '/groupfeeds/create',
//               '/feeds/',
//               '/groupfeeds/',
//               '/signup',
//               '/login',
//               '/chat/',
//               '/route',
//             ].any((path) => location.startsWith(path));
//
//             return Scaffold(
//               backgroundColor: Colors.white,
//
//               appBar: showShellAppBar ? CustomAppBar(appBarType: AppBarType.back) : null,
//               bottomNavigationBar: showBottomNav
//                   ? BottomNavBar(currentLocation: location)
//                   : null,
//               body: child,
//             );
//           },
//
//           routes: [
//             GoRoute(path: '/', builder: (_, __) => FeedListScreen()),
//             GoRoute(path: '/signup', builder: (_, __) => SignupScreen()),
//             GoRoute(path: '/login', builder: (_, __) => LoginModalScreen()),
//             GoRoute(path: '/profile', builder: (_, __) => MyProfileScreen()),
//             GoRoute(path: '/map', builder: (_, __) => MapScreen()),
//             GoRoute(path: '/chat', builder: (_, __) => ChatRoomListScreen()),
//             GoRoute(path: '/ranking', builder: (_, __) => RankingScreen()),
//             GoRoute(
//               path: '/chat/:chatRoomId',
//               builder:
//                   (_, state) => ChatRoomScreen(
//                 chatRoomId: state.pathParameters['chatRoomId']!,
//               ),
//             ),
//             GoRoute(
//               path: '/feeds/create',
//               builder: (_, __) => FeedCreateScreen(),
//             ),
//             GoRoute(
//               path: '/groupfeeds/create',
//               builder: (_, __) => GroupFeedCreateScreen(),
//             ),
//             GoRoute(
//               path: '/feeds/:feedId',
//               builder:
//                   (_, state) =>
//                   FeedDetailScreen(feedId: state.pathParameters['feedId']!),
//             ),
//             GoRoute(
//               path: '/feeds/:feedId/edit',
//               builder:
//                   (_, state) =>
//                   FeedEditScreen(feedId: state.pathParameters['feedId']!),
//             ),
//             GoRoute(
//               path: '/groupfeeds/:groupFeedId',
//               builder:
//                   (_, state) => GroupFeedDetailScreen(
//                 groupFeedId: state.pathParameters['groupFeedId']!,
//               ),
//             ),
//             GoRoute(
//               path: '/groupfeeds/:groupFeedId/edit',
//               builder:
//                   (_, state) => GroupFeedEditScreen(
//                 groupFeedId: state.pathParameters['groupFeedId']!,
//               ),
//             ),
//             GoRoute(
//               path: '/me/feeds',
//               builder: (context, state) => MyFeedScreen(),
//             ),
//             GoRoute(
//               path: '/me/liked-feeds',
//               builder: (context, state) => MyLikedFeedScreen(),
//             ),
//             GoRoute(
//               path: '/me/followers',
//               builder:
//                   (_, state) => FollowListScreen(
//                 username: 'me', // 내 프로필의 경우 'me'로 처리
//                 isFollowers: true,
//               ),
//             ),
//             GoRoute(
//               path: '/me/following',
//               builder:
//                   (_, state) => FollowListScreen(
//                 username: 'me', // 내 프로필의 경우 'me'로 처리
//                 isFollowers: false,
//               ),
//             ),
//             GoRoute(
//               path: '/user/:username',
//               builder:
//                   (_, state) => UserProfileScreen(
//                 username: state.pathParameters['username']!,
//               ),
//             ),
//             GoRoute(
//               path: '/user/:username/feeds',
//               builder:
//                   (_, state) => UserFeedScreen(
//                 username: state.pathParameters['username']!,
//               ),
//             ),
//             GoRoute(
//               path: '/user/:username/followers',
//               builder:
//                   (_, state) => FollowListScreen(
//                 username: state.pathParameters['username']!,
//                 isFollowers: true,
//               ),
//             ),
//             GoRoute(
//               path: '/user/:username/following',
//               builder:
//                   (_, state) => FollowListScreen(
//                 username: state.pathParameters['username']!,
//                 isFollowers: false,
//               ),
//             ),
//             GoRoute(
//               path: '/route',
//               builder: (context, state) {
//                 //state.extra에서 전체 레코드 꺼내기
//                 final record = state.extra as Map<String, dynamic>;
//
//                 //레코드 시간 정보
//                 final runningDate = DateFormat(
//                   'yyyy년 M월 d일 \na h시 m분',
//                   'ko_KR',
//                 ).format(DateTime.parse(record['createdAt'] as String).toLocal());
//
//                 //경로(path) 변환: List<dynamic> → List<LatLng>
//                 final rawPath = record['path'] as List<dynamic>;
//                 final path =
//                 rawPath
//                     .map(
//                       (p) => LatLng(
//                     p['latitude'] as double,
//                     p['longitude'] as double,
//                   ),
//                 )
//                     .toList();
//
//                 //거리·시간·페이스 계산
//                 final distanceKm = (record['totalDistance'] as num) / 1000;
//                 final totalSeconds = record['totalSeconds'] as int;
//                 final totalTime = Duration(seconds: totalSeconds);
//                 final timeStr = [
//                   totalTime.inHours.toString().padLeft(2, '0'),
//                   (totalTime.inMinutes % 60).toString().padLeft(2, '0'),
//                   (totalTime.inSeconds % 60).toString().padLeft(2, '0'),
//                 ].join(':');
//                 final paceSec = distanceKm > 0 ? (totalTime.inSeconds / distanceKm).round() : 0;
//                 final pace = Duration(seconds: paceSec);
//                 final paceStr =
//                     '${pace.inMinutes.toString().padLeft(2, '0')}:${(pace.inSeconds % 60).toString().padLeft(2, '0')}';
//
//                 // 4) RouteScreen에 모든 정보 전달
//                 return RouteScreen(
//                   path: path,
//                   distanceKm: distanceKm,
//                   timeStr: timeStr,
//                   paceStr: paceStr,
//                   runningDateStr: runningDate,
//                 );
//               },
//             ),
//           ],
//         ),
//       ],
//     );
//
//     return MaterialApp.router(
//       title: 'Crewer App',
//       theme: ThemeData(
//         scaffoldBackgroundColor: Colors.white,
//         primaryColor: const Color(0xFF9CB4CD),
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       routerConfig: router,
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

// import 'package:client/providers/auth_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:client/components/top_navbar.dart';
// import 'package:client/components/bottom_navbar.dart';
//
// import 'package:client/screens/feed_list_screen.dart';
// import 'package:client/screens/feed_create_screen.dart';
// import 'package:client/screens/feed_edit_screen.dart';
// import 'package:client/screens/feed_detail_screen.dart';
// import 'package:client/screens/group_feed_create_screen.dart';
// import 'package:client/screens/group_feed_edit_screen.dart';
// import 'package:client/screens/group_feed_detail_screen.dart';
// import 'package:client/screens/map_screen.dart';
// import 'package:client/screens/my_profile_screen.dart';
// import 'package:client/screens/user_profile_screen.dart';
// import 'package:client/screens/user_feed_screen.dart';
// import 'package:client/screens/signup_screen.dart';
// import 'package:client/screens/chatroom_list_screen.dart';
// import 'package:client/screens/chatroom_screen.dart';
// import 'package:client/screens/ranking_screen.dart';
// import 'package:client/components/login_modal_screen.dart';
// import 'package:client/screens/my_feed_screen.dart';
// import 'package:client/screens/my_liked_feed_screen.dart';
// import 'package:client/screens/running_route_screen.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:client/screens/follow_list_screen.dart';
// import 'package:provider/provider.dart';
//
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(
//     ChangeNotifierProvider(
//       // AuthProvider 인스턴스를 생성하고, 앱 시작 시 로그인 상태를 확인합니다.
//       create: (context) => AuthProvider()..checkLoginStatus(),
//       child: const MyApp(),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final GoRouter router = GoRouter(
//       initialLocation: '/',
//       routes: [
//         ShellRoute(
//           builder: (context, state, child) {
//             final location = state.uri.toString();
//
//             // 하단바 + 상단바 같이 쓰는 페이지
//             final showBottomNav =
//                 ![
//                   '/feeds/create',
//                   '/groupfeeds/create',
//                   '/feeds/',
//                   '/groupfeeds/',
//                   '/signup',
//                   '/chat/',
//                 ].any((path) => location.startsWith(path));
//
//             return Scaffold(
//               backgroundColor: Colors.white,
//               appBar: TopNavBar(onBack: () => context.pop()),
//               bottomNavigationBar:
//                   showBottomNav
//                       ? BottomNavBar(currentLocation: location)
//                       : null,
//               body: child,
//             );
//           },
//           routes: [
//             GoRoute(path: '/', builder: (_, __) => FeedListScreen()),
//             GoRoute(path: '/signup', builder: (_, __) => SignupScreen()),
//             GoRoute(path: '/login', builder: (_, __) => LoginModalScreen()),
//             GoRoute(path: '/profile', builder: (_, __) => MyProfileScreen()),
//             GoRoute(path: '/map', builder: (_, __) => MapScreen()),
//             GoRoute(path: '/chat', builder: (_, __) => ChatRoomListScreen()),
//             GoRoute(path: '/ranking', builder: (_, __) => RankingScreen()),
//             GoRoute(
//               path: '/chat/:chatRoomId',
//               builder:
//                   (_, state) => ChatRoomScreen(
//                     chatRoomId: state.pathParameters['chatRoomId']!,
//                   ),
//             ),
//             GoRoute(
//               path: '/feeds/create',
//               builder: (_, __) => FeedCreateScreen(),
//             ),
//             GoRoute(
//               path: '/groupfeeds/create',
//               builder: (_, __) => GroupFeedCreateScreen(),
//             ),
//             GoRoute(
//               path: '/feeds/:feedId',
//               builder:
//                   (_, state) =>
//                       FeedDetailScreen(feedId: state.pathParameters['feedId']!),
//             ),
//             GoRoute(
//               path: '/feeds/:feedId/edit',
//               builder:
//                   (_, state) =>
//                       FeedEditScreen(feedId: state.pathParameters['feedId']!),
//             ),
//             GoRoute(
//               path: '/groupfeeds/:groupFeedId',
//               builder:
//                   (_, state) => GroupFeedDetailScreen(
//                     groupFeedId: state.pathParameters['groupFeedId']!,
//                   ),
//             ),
//             GoRoute(
//               path: '/groupfeeds/:groupFeedId/edit',
//               builder:
//                   (_, state) => GroupFeedEditScreen(
//                     groupFeedId: state.pathParameters['groupFeedId']!,
//                   ),
//             ),
//             GoRoute(
//               path: '/me/feeds',
//               builder: (context, state) => MyFeedScreen(),
//             ),
//             GoRoute(
//               path: '/me/liked-feeds',
//               builder: (context, state) => MyLikedFeedScreen(),
//             ),
//             GoRoute(
//               path: '/me/followers',
//               builder:
//                   (_, state) => FollowListScreen(
//                     username: 'me', // 내 프로필의 경우 'me'로 처리
//                     isFollowers: true,
//                   ),
//             ),
//             GoRoute(
//               path: '/me/following',
//               builder:
//                   (_, state) => FollowListScreen(
//                     username: 'me', // 내 프로필의 경우 'me'로 처리
//                     isFollowers: false,
//                   ),
//             ),
//             GoRoute(
//               path: '/user/:username',
//               builder:
//                   (_, state) => UserProfileScreen(
//                     username: state.pathParameters['username']!,
//                   ),
//             ),
//             GoRoute(
//               path: '/user/:username/feeds',
//               builder:
//                   (_, state) => UserFeedScreen(
//                     username: state.pathParameters['username']!,
//                   ),
//             ),
//             GoRoute(
//               path: '/user/:username/followers',
//               builder:
//                   (_, state) => FollowListScreen(
//                     username: state.pathParameters['username']!,
//                     isFollowers: true,
//                   ),
//             ),
//             GoRoute(
//               path: '/user/:username/following',
//               builder:
//                   (_, state) => FollowListScreen(
//                     username: state.pathParameters['username']!,
//                     isFollowers: false,
//                   ),
//             ),
//             GoRoute(
//               path: '/route',
//               builder: (context, state) {
//                 //state.extra에서 전체 레코드 꺼내기
//                 final record = state.extra as Map<String, dynamic>;
//
//                 //레코드 시간 정보
//                 final runningDate = DateFormat(
//                   'yyyy년 M월 d일 \na h시 m분',
//                   'ko_KR',
//                 ).format(DateTime.parse(record['createdAt'] as String));
//
//                 //경로(path) 변환: List<dynamic> → List<LatLng>
//                 final rawPath = record['path'] as List<dynamic>;
//                 final path =
//                     rawPath
//                         .map(
//                           (p) => LatLng(
//                             p['latitude'] as double,
//                             p['longitude'] as double,
//                           ),
//                         )
//                         .toList();
//
//                 //거리·시간·페이스 계산
//                 final distanceKm = (record['totalDistance'] as num) / 1000;
//                 final totalSeconds = record['totalSeconds'] as int;
//                 final totalTime = Duration(seconds: totalSeconds);
//                 final timeStr = [
//                   totalTime.inHours.toString().padLeft(2, '0'),
//                   (totalTime.inMinutes % 60).toString().padLeft(2, '0'),
//                   (totalTime.inSeconds % 60).toString().padLeft(2, '0'),
//                 ].join(':');
//                 final paceSec = (totalTime.inSeconds / distanceKm).round();
//                 final pace = Duration(seconds: paceSec);
//                 final paceStr =
//                     '${pace.inMinutes.toString().padLeft(2, '0')}:${(pace.inSeconds % 60).toString().padLeft(2, '0')}';
//
//                 // 4) RouteScreen에 모든 정보 전달
//                 return RouteScreen(
//                   path: path,
//                   distanceKm: distanceKm,
//                   timeStr: timeStr,
//                   paceStr: paceStr,
//                   runningDateStr: runningDate,
//                 );
//               },
//             ),
//           ],
//         ),
//       ],
//     );
//
//     return MaterialApp.router(
//       title: 'Crewer App',
//       theme: ThemeData(
//         scaffoldBackgroundColor: Colors.white,
//         primaryColor: const Color(0xFF9CB4CD),
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       routerConfig: router,
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
