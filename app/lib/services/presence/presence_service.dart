import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';

final presenceServiceProvider = Provider<PresenceService>((ref) {
  return PresenceService(FirebaseDatabase.instance, ref);
});

class PresenceService {
  final FirebaseDatabase _db;
  final Ref _ref;

  StreamSubscription? _connectedSub;

  PresenceService(this._db, this._ref);

  /// Configures automatic presence management for a specific room.
  /// Uses .info/connected to handle reconnects and onDisconnect() for clean-up.
  ///
  /// Cancels any previous .info/connected listener before creating a new one
  /// to prevent subscription accumulation across room navigations.
  void trackPresence(String roomId) {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final playerId = user.uid;
    final presenceRef = _db.ref('rooms/$roomId/players/$playerId/isPresent');
    final connectedRef = _db.ref('.info/connected');

    _connectedSub?.cancel();
    _connectedSub = connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        // When connected, set presence to true and configure onDisconnect
        presenceRef.set(true);
        presenceRef.onDisconnect().set(false);
      }
    });
  }

  /// Cancels the active .info/connected listener.
  /// Call from the widget's dispose() to prevent subscription accumulation.
  void stopTracking() {
    _connectedSub?.cancel();
    _connectedSub = null;
  }
}
