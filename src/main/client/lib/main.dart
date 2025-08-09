// main.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/top_navbar.dart';
import 'package:client/components/bottom_navbar.dart';

// Screens import 생략 (기존처럼 유지)
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
import 'package:client/screens/follow_list_screen.dart';
import 'package:client/screens/running_route_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            final location = state.uri.toString();

            // 하단바 + 상단바 같이 쓰는 페이지
            final showBottomNav = !['/feeds/create', '/groupfeeds/create', '/feeds/', '/groupfeeds/', '/signup', '/chat/']
                .any((path) => location.startsWith(path));

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: TopNavBar(onBack: () => context.pop()),
              bottomNavigationBar:
              showBottomNav ? BottomNavBar(currentLocation: location) : null,
              body: child,
            );
          },
          routes: [
            GoRoute(path: '/', builder: (_, __) => FeedListScreen()),
            GoRoute(path: '/signup', builder: (_, __) => SignupScreen()),
            GoRoute(path: '/login', builder: (_, __) => LoginModalScreen()),
            GoRoute(path: '/profile', builder: (_, __) => MyProfileScreen()),
            GoRoute(path: '/map', builder: (_, __) => MapScreen()),
            GoRoute(path: '/chat', builder: (_, __) => ChatRoomListScreen()),
            GoRoute(path: '/ranking', builder: (_, __) => RankingScreen()),
            GoRoute(
              path: '/chat/:chatRoomId',
              builder: (_, state) => ChatRoomScreen(chatRoomId: state.pathParameters['chatRoomId']!),
            ),
            GoRoute(path: '/feeds/create', builder: (_, __) => FeedCreateScreen()),
            GoRoute(path: '/groupfeeds/create', builder: (_, __) => GroupFeedCreateScreen()),
            GoRoute(
              path: '/feeds/:feedId',
              builder: (_, state) => FeedDetailScreen(feedId: state.pathParameters['feedId']!),
            ),
            GoRoute(
              path: '/feeds/:feedId/edit',
              builder: (_, state) => FeedEditScreen(feedId: state.pathParameters['feedId']!),
            ),
            GoRoute(
              path: '/groupfeeds/:groupFeedId',
              builder: (_, state) => GroupFeedDetailScreen(groupFeedId: state.pathParameters['groupFeedId']!),
            ),
            GoRoute(
              path: '/groupfeeds/:groupFeedId/edit',
              builder: (_, state) => GroupFeedEditScreen(groupFeedId: state.pathParameters['groupFeedId']!),
            ),
            GoRoute(
              path: '/me/feeds',
              builder: (context, state) => MyFeedScreen(),
            ),
            GoRoute(
              path: '/me/liked-feeds',
              builder: (context, state) => MyLikedFeedScreen(),
            ),
            GoRoute(
              path: '/user/:username',
              builder: (_, state) => UserProfileScreen(username: state.pathParameters['username']!),
            ),
            GoRoute(
              path: '/user/:username/feeds',
              builder: (_, state) => UserFeedScreen(username: state.pathParameters['username']!),
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