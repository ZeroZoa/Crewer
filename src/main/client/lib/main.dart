import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';

// Screens import
//  Feed Screen
import 'package:client/screens/feed_list_screen.dart';
import 'package:client/screens/feed_detail_screen.dart';
import 'package:client/screens/feed_create_screen.dart';
import 'package:client/screens/feed_edit_screen.dart';

// Group Feed Screen
import 'package:client/screens/group_feed_detail_screen.dart';
import 'package:client/screens/group_feed_create_screen.dart';
import 'package:client/screens/group_feed_edit_screen.dart';

// Chat Screen
import 'package:client/screens/chatroom_list_screen.dart';
import 'package:client/screens/chatroom_screen.dart';

// Map Screen
import 'package:client/screens/map_screen.dart';


// About User
import 'package:client/screens/signup_screen.dart';
import 'package:client/components/login_modal_screen.dart';
import 'package:client/screens/my_profile_screen.dart';

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
        GoRoute(
          path: '/',
          builder: (context, state) => FeedListScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => SignupScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginModalScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => MyProfileScreen(),
        ),
        GoRoute(
          path: '/feeds/create',
          builder: (context, state) => FeedCreateScreen(),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => MapScreen(),
        ),
        GoRoute(
          path: '/feeds/:feedId/edit',
          builder: (context, state) {
            final feedId = state.pathParameters['feedId']!;
            return FeedEditScreen(feedId: feedId);
          },
        ),
        GoRoute(
          path: '/feeds/:feedId',
          builder: (context, state) {
            final feedId = state.pathParameters['feedId']!;
            return FeedDetailScreen(feedId: feedId);
          },
        ),
        GoRoute(
          path: '/groupfeeds/create',
          builder: (context, state) => const GroupFeedCreateScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => const ChatRoomListScreen(),
        ),
        GoRoute(
          path: '/chat/:chatRoomId',
          builder: (context, state) {
            final chatRoomId = state.pathParameters['chatRoomId']!;
            return ChatRoomScreen(chatRoomId: chatRoomId);
          },
        ),
        GoRoute(
          path: '/groupfeeds/:groupFeedId/edit',
          builder: (context, state) {
            final groupFeedId = state.pathParameters['groupFeedId']!;
            return GroupFeedEditScreen(groupFeedId: groupFeedId);
          },
        ),
        GoRoute(
          path: '/groupfeeds/:groupFeedId',
          builder: (context, state) {
            final groupFeedId = state.pathParameters['groupFeedId']!;
            return GroupFeedDetailScreen(groupFeedId: groupFeedId);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Crewer App',
      theme: ThemeData(
        primaryColor: const Color(0xFF9CB4CD),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
