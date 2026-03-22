import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/question.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository(FirebaseFirestore.instance);
});

class QuestionRepository {
  final FirebaseFirestore _firestore;

  QuestionRepository(this._firestore);

  /// Fetches a random question from a single pack, excluding already used questions.
  Future<Question?> fetchRandomQuestion({
    required String packId,
    required List<String> excludedIds,
  }) =>
      fetchRandomQuestionFromPacks(packIds: [packId], excludedIds: excludedIds);

  /// Fetches a random question from any of the given packs, excluding used IDs.
  /// Uses a single Firestore whereIn query (up to 30 pack IDs).
  Future<Question?> fetchRandomQuestionFromPacks({
    required List<String> packIds,
    required List<String> excludedIds,
  }) async {
    if (packIds.isEmpty) return null;

    final query = _firestore
        .collection('question_bank')
        .where('packId', whereIn: packIds.take(30).toList());

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return null;

    final availableQuestions = snapshot.docs
        .where((doc) => !excludedIds.contains(doc.id))
        .toList();

    if (availableQuestions.isEmpty) return null;

    availableQuestions.shuffle();
    final doc = availableQuestions.first;

    return Question.fromJson({
      'id': doc.id,
      'textEn': '', // default prevents null cast in generated fromJson
      ...doc.data(),
    });
  }

  /// Fetches ALL questions from the given pack IDs in a single Firestore query.
  ///
  /// Used by [SessionQuestionEngine] for pre-session queue generation.
  /// Client-side filtering (status, intensity, ageRating) is applied by the
  /// engine — this method is an intentionally raw fetch.
  ///
  /// Existing Firestore docs lacking the new metadata fields parse correctly
  /// because [Question] uses @Default() for those fields.
  Future<List<Question>> fetchAllQuestionsFromPacks({
    required List<String> packIds,
  }) async {
    if (packIds.isEmpty) return [];

    final snapshot = await _firestore
        .collection('question_bank')
        .where('packId', whereIn: packIds.take(30).toList())
        .get();

    return snapshot.docs
        .map((doc) => Question.fromJson({
              'id': doc.id,
              'textEn': '', // safe default — prevents null cast in generated fromJson
              ...doc.data(),
            }))
        .toList();
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
