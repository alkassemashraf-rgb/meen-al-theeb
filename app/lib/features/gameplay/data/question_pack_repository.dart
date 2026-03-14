import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/question_pack.dart';

final questionPackRepositoryProvider = Provider<QuestionPackRepository>((ref) =>
    QuestionPackRepository(FirebaseFirestore.instance));

/// Loads all packs from Firestore once. Cached by Riverpod for the lifetime
/// of the provider scope.
final allPacksProvider = FutureProvider<List<QuestionPack>>((ref) =>
    ref.read(questionPackRepositoryProvider).fetchAllPacks());

/// Host's selected pack in the lobby. `null` means no explicit selection —
/// [GameSessionRepository.startGame] falls back to [getDefaultPackId].
/// Scoped per roomId to match existing `.family` provider patterns.
final selectedPackProvider =
    StateProvider.family<String?, String>((ref, roomId) => null);

class QuestionPackRepository {
  final FirebaseFirestore _firestore;

  QuestionPackRepository(this._firestore);

  /// Fetches all question packs ordered by name.
  Future<List<QuestionPack>> fetchAllPacks() async {
    final snapshot = await _firestore
        .collection('questionPacks')
        .orderBy('name')
        .get();
    return snapshot.docs
        .map((doc) =>
            QuestionPack.fromJson({'packId': doc.id, ...doc.data()}))
        .toList();
  }
}
