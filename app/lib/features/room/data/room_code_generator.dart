import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

class RoomCodeGenerator {
  static const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluded confusing chars like O,0,I,1
  static const int _codeLength = 5;

  /// Generates a unique 5-character alphanumeric join code.
  static Future<String> generateUniqueCode(DatabaseReference roomsRef) async {
    final random = Random.secure();
    
    // Attempt generation up to 10 times to prevent infinite loops (highly unlikely to collide at MVP scale)
    for (int i = 0; i < 10; i++) {
      final code = String.fromCharCodes(Iterable.generate(
        _codeLength,
        (_) => _chars.codeUnitAt(random.nextInt(_chars.length)),
      ));

      // Check if this join code exists in active rooms
      // Note: We use the 'room_codes' index in the DB to make this check atomic/fast
      final db = FirebaseDatabase.instance;
      final existingCode = await db.ref('room_codes/$code').get();
      
      if (!existingCode.exists) {
        return code;
      }
    }
    
    throw Exception('Failed to generate a unique room code. Please try again.');
  }
}
