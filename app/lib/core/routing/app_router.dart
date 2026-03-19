import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/test_backend/test_backend_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/room/presentation/create_room_screen.dart';
import '../../features/room/presentation/join_room_screen.dart';
import '../../features/room/presentation/lobby_screen.dart' as room_lobby;
import '../../features/gameplay/presentation/gameplay_screen.dart';
import '../../features/gameplay/presentation/session_summary_screen.dart';
import '../../features/room/presentation/avatar_selection_screen.dart';

// Placeholder Screens
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Screen: $title')),
    );
  }
}

final appRouter = GoRouter(
  initialLocation: '/home',
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFF1A1330),
    body: Center(
      child: Text(
        'Navigation error:\n${state.error}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    ),
  ),
  routes: [
    GoRoute(
      path: '/test-backend',
      builder: (context, state) => const TestBackendScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const PlaceholderScreen(title: 'Onboarding'),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const PlaceholderScreen(title: 'Profile'),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/create-room',
      builder: (context, state) => const CreateRoomScreen(),
    ),
    GoRoute(
      path: '/join-room',
      builder: (context, state) => const JoinRoomScreen(),
    ),
    GoRoute(
      path: '/room/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        return room_lobby.LobbyScreen(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/gameplay/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        return GameplayScreen(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/summary/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        return SessionSummaryScreen(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/select-avatar',
      builder: (context, state) {
        final initialId = state.uri.queryParameters['initialId'];
        return AvatarSelectionScreen(initialAvatarId: initialId);
      },
    ),
    GoRoute(
      path: '/reveal',
      builder: (context, state) => const PlaceholderScreen(title: 'Reveal'),
    ),
  ],
);

