import 'package:client/components/custom_app_bar.dart';
import 'package:client/providers/auth_provider.dart';
import 'package:client/screens/group_feed_list_screen.dart';
import 'package:client/screens/ranking_detail_screen.dart';
import 'package:client/screens/main_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/bottom_navbar.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// Screens
import 'package:client/screens/splash_screen.dart';
import 'package:client/screens/start_screen.dart';
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
import 'package:client/screens/login_screen.dart';
import 'package:client/screens/my_feed_screen.dart';
import 'package:client/screens/my_liked_feed_screen.dart';
import 'package:client/screens/running_route_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:client/screens/follow_list_screen.dart';
import 'package:client/screens/profile_setup_screen.dart';
import 'package:client/screens/profile_interests_screen.dart';
import 'package:client/screens/profile_complete_screen.dart';
import 'package:client/screens/main_screen.dart';
import 'package:client/screens/reset_password_screen.dart';
import 'package:client/screens/place_picker_screen.dart';

import 'models/my_ranking_info.dart';
import 'models/ranking_info.dart';


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
      initialLocation: '/splash',
      routes: [
        
        ShellRoute(
          builder: (context, state, child) {
            final location = state.uri.toString();


            // 1. 하단바가 '무조건' 보여야 하는 경로 목록
            final bottomNavRoutes = ['/', '/feeds','/groupfeeds','/map', '/ranking', '/chat', '/profile', '/route', '/user/'];

            final showBottomNav = bottomNavRoutes.contains(state.uri.toString());

            // 2. 현재 경로가 위 목록에 정확히 일치하는지 확인 (프로필 설정 관련 경로 제외)
            // final showBottomNav = bottomNavRoutes.any((route) => location.startsWith(route)) &&
            //     !location.startsWith('/profile-setup') &&
            //     !location.startsWith('/signup') &&
            //     !location.startsWith('/login') &&
            //     !location.startsWith('/start') &&
            //     !location.startsWith('/splash');

            return Scaffold(
              backgroundColor: Colors.white,
              bottomNavigationBar: showBottomNav
                  ? BottomNavBar(currentLocation: state.uri.toString())
                  : null,
              body: child,
            );
          },
          routes: [
            // --- 화면 경로 목록 ---
            GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
            GoRoute(path: '/start', builder: (_, __) => StartScreen()),
            GoRoute(path: '/', builder: (_, __) =>  MainScreen()),
            GoRoute(path: '/mainsearch', builder: (_, __) =>  MainSearchScreen()),
            GoRoute(path: '/feeds', builder: (_, __) =>  FeedListScreen()),
            GoRoute(path: '/groupfeeds', builder: (_, __) =>  GroupFeedListScreen()),
            GoRoute(path: '/signup', builder: (_, __) =>  SignupScreen()),
            GoRoute(path: '/login', builder: (_, __) =>  LoginScreen()),
            GoRoute(path: '/profile-setup', builder: (_, __) =>  ProfileSetupScreen()),
            GoRoute(path: '/profile-setup/interests', builder: (_, __) =>  ProfileInterestsScreen()),
            GoRoute(path: '/profile-setup/complete', builder: (_, __) =>  ProfileCompleteScreen()),
            GoRoute(path: '/profile', builder: (_, __) =>  MyProfileScreen()),
            GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
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
              path: '/place-picker',
              builder: (_, __) => const PlacePickerScreen(),
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
            //달리기 경로를 보여주기 위한 페이지에 데이터를 넘겨주기
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
            //랭킹을 보여주기 위한 페이지에 데이터 넘겨주기
            GoRoute(
              path: '/ranking/:category',
              builder: (context, state) {
                // URL 경로에서 category 파라미터 추출
                final category = state.pathParameters['category']!;

                // extra로 전달받은 데이터 추출
                final data = state.extra as Map<String, dynamic>?;

                // 데이터가 없는 경우를 대비한 기본값 처리
                final myRankInfo = data?['myRankInfo'] as MyRankingInfo?;
                final topRankings = data?['topRankings'] as List<RankingInfo>? ?? [];

                return RankingDetailScreen(
                  category: category,
                  myRankInfo: myRankInfo,
                  topRankings: topRankings,
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