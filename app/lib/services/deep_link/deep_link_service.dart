import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/routing/app_router.dart';

class DeepLinkState {
  final String? pendingRoomCode;
  const DeepLinkState({this.pendingRoomCode});
  const DeepLinkState.empty() : pendingRoomCode = null;
  DeepLinkState cleared() => const DeepLinkState.empty();
}

class DeepLinkService extends AsyncNotifier<DeepLinkState> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  Future<DeepLinkState> build() async {
    ref.onDispose(() => _sub?.cancel());

    // Cold start: URI from the tap that launched the app.
    // getInitialLink() returns null when the app was opened normally.
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      final code = _extract(initialUri);
      if (code != null) {
        // Store as pending — SplashScreen reads and consumes this before
        // navigating to /home, redirecting to /join-room?code=X instead.
        return DeepLinkState(pendingRoomCode: code);
      }
    }

    // Foreground: URIs delivered while the app is already running.
    // The router is mounted by this point, so navigate directly.
    _sub = _appLinks.uriLinkStream.listen((uri) {
      final code = _extract(uri);
      if (code == null) return;
      ref.read(routerProvider).go('/join-room?code=$code');
    });

    return const DeepLinkState.empty();
  }

  /// Called by SplashScreen after it has consumed the pending room code.
  void clearPendingCode() {
    if (state.valueOrNull?.pendingRoomCode != null) {
      state = AsyncData(state.requireValue.cleared());
    }
  }

  /// Extracts a 5-char room code from a meenaltheeb://join?room=XXXXX URI.
  String? _extract(Uri uri) {
    if (uri.scheme == 'meenaltheeb' && uri.host == 'join') {
      final code = uri.queryParameters['room'];
      if (code != null && code.length == 5) return code.toUpperCase();
    }
    return null;
  }
}

final deepLinkServiceProvider =
    AsyncNotifierProvider<DeepLinkService, DeepLinkState>(DeepLinkService.new);
