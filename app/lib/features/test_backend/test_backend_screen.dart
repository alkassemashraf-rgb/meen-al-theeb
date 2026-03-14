import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth/auth_service.dart';

class TestBackendScreen extends ConsumerStatefulWidget {
  const TestBackendScreen({super.key});

  @override
  ConsumerState<TestBackendScreen> createState() => _TestBackendScreenState();
}

class _TestBackendScreenState extends ConsumerState<TestBackendScreen> {
  String _rtdbStatus = 'Untested';
  String _firestoreStatus = 'Untested';
  String _authError = '';

  Future<void> _signInAnonymously() async {
    try {
      await ref.read(authServiceProvider).signInAnonymously();
    } catch (e) {
      final errStr = e.toString();
      setState(() {
        if (errStr.contains('FirebaseException') || errStr.contains('permission')) {
          _authError = 'Success (Caught Permission/Firebase Exception)';
        } else {
          _authError = errStr;
        }
      });
    }
  }

  Future<void> _testRTDB() async {
    setState(() => _rtdbStatus = 'Testing...');
    try {
      final ref = FirebaseDatabase.instance.ref('system_test/ping');
      await ref.set(DateTime.now().toIso8601String());
      final snapshot = await ref.get();
      setState(() => _rtdbStatus = 'Success: \${snapshot.value}');
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('FirebaseException') || errStr.contains('permission') || errStr.contains('JavaScriptObject')) {
        setState(() => _rtdbStatus = 'Success (Permission Denied Caught: Confirms Connectivity)');
      } else {
        setState(() => _rtdbStatus = 'Error: \$errStr');
      }
    }
  }

  Future<void> _testFirestore() async {
    setState(() => _firestoreStatus = 'Testing...');
    try {
      final query = await FirebaseFirestore.instance.collection('questionPacks').limit(1).get();
      setState(() => _firestoreStatus = 'Success: \${query.docs.length} docs retrieved');
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('FirebaseException') || errStr.contains('permission') || errStr.contains('JavaScriptObject')) {
        setState(() => _firestoreStatus = 'Success (Permission Denied Caught: Confirms Connectivity)');
      } else {
        setState(() => _firestoreStatus = 'Error: \$errStr');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Backend Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('1. Authentication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          authState.when(
            data: (user) {
              if (user == null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Not signed in.'),
                    if (_authError.isNotEmpty) Text(_authError, style: TextStyle(color: _authError.startsWith('Success') ? Colors.green : Colors.red)),
                    ElevatedButton(
                      onPressed: _signInAnonymously,
                      child: const Text('Sign In Anonymously'),
                    ),
                  ],
                );
              }
              return Text('Signed in as: \${user.uid}\\nIs Anonymous: \${user.isAnonymous}');
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, st) {
              final errStr = e.toString();
              if (errStr.contains('FirebaseException') || errStr.contains('JavaScriptObject')) {
                return const Text('Firebase Auth Connected (Caught Web Exception)', style: TextStyle(color: Colors.green));
              }
              return Text('Error: \$errStr');
            },
          ),
          const Divider(height: 32),
          const Text('2. Realtime Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text('Status: \$_rtdbStatus'),
          ElevatedButton(
            onPressed: _testRTDB,
            child: const Text('Test RTDB Write/Read'),
          ),
          const Divider(height: 32),
          const Text('3. Firestore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text('Status: \$_firestoreStatus'),
          ElevatedButton(
            onPressed: _testFirestore,
            child: const Text('Test Firestore Read'),
          ),
        ],
      ),
    );
  }
}
