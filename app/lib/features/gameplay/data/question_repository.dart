import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/question.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository(FirebaseFirestore.instance);
});

class QuestionRepository {
  final FirebaseFirestore _firestore;

  QuestionRepository(this._firestore);

  /// Fetches a random question from a pack, excluding already used questions
  Future<Question?> fetchRandomQuestion({
    required String packId,
    required List<String> excludedIds,
  }) async {
    final query = _firestore
        .collection('questions')
        .where('packId', isEqualTo: packId);

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return null;

    final availableQuestions = snapshot.docs
        .where((doc) => !excludedIds.contains(doc.id))
        .toList();

    if (availableQuestions.isEmpty) return null;

    // Pick a random one from available
    availableQuestions.shuffle();
    final doc = availableQuestions.first;
    
    return Question.fromJson({
      'id': doc.id,
      ...doc.data(),
    });
  }

  /// Helper to fetch a default pack ID if none provided
  Future<String> getDefaultPackId() async {
    final snapshot = await _firestore.collection('questionPacks').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return 'default_pack';
  }
}
