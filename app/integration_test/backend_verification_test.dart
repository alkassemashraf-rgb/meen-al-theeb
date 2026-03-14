import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meen_al_theeb/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Mission 3.5 Backend Environment Verification', () {
    testWidgets('Firebase initializes successfully', (WidgetTester tester) async {
      final app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      expect(app, isNotNull);
      print('Firebase initialized: \${app.name}');
    });

    testWidgets('Anonymous Auth returns UID', (WidgetTester tester) async {
      final auth = FirebaseAuth.instance;
      // Start clean
      if (auth.currentUser != null) {
        await auth.signOut();
      }
      expect(auth.currentUser, isNull);

      final credential = await auth.signInAnonymously();
      expect(credential.user, isNotNull);
      expect(credential.user!.isAnonymous, isTrue);
      print('Anonymous Auth UID: \${credential.user!.uid}');
    });

    testWidgets('Realtime Database connectivity test', (WidgetTester tester) async {
      final ref = FirebaseDatabase.instance.ref('system_test/ping');
      try {
        await ref.set('test_ping_\${DateTime.now().millisecondsSinceEpoch}');
        final snapshot = await ref.get();
        expect(snapshot.exists, isTrue);
        print('RTDB connectivity verified. Wrote and read ping.');
      } catch (e) {
        // If security rules block the write (which they should per Mission 3 rules unless we specified otherwise)
        // we capture it as 'PERMISSION_DENIED', which still proves connectivity to the backend project.
        print('RTDB test resulted in error (Connectivity Success): \$e');
        // We consider the test passed if it connected, even if it was rejected by security rules.
        expect(e.toString().contains('Permission denied') || e.toString().contains('permission_denied'), isTrue, reason: 'Expected either success or permission denied. Got: \$e');
      }
    });

    testWidgets('Firestore connectivity test', (WidgetTester tester) async {
      final collection = FirebaseFirestore.instance.collection('questionPacks');
      try {
        final query = await collection.limit(1).get();
        print('Firestore connectivity verified. Retrieved \${query.docs.length} docs.');
      } catch (e) {
         print('Firestore test resulted in error (Connectivity Success): \$e');
         expect(e.toString().contains('permission-denied') || e.toString().contains('Permission denied'), isTrue, reason: 'Expected either success or permission denied. Got: \$e');
      }
    });
  });
}
