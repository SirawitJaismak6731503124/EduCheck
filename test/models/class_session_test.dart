import 'package:flutter_test/flutter_test.dart';

import 'package:edu_check/models/class_session.dart';

void main() {
  final checkIn = DateTime(2026, 3, 13, 9, 0);
  final checkOut = DateTime(2026, 3, 13, 10, 30);

  ClassSession makeSession({
    String id = 'session-001',
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double startLat = 13.7563,
    double startLng = 100.5018,
    double? endLat,
    double? endLng,
    String prevTopic = 'Flutter basics',
    String expectedTopic = 'State management',
    int mood = 4,
    String? learnedText,
    String? feedback,
  }) =>
      ClassSession(
        id: id,
        checkInTime: checkInTime ?? checkIn,
        checkOutTime: checkOutTime,
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        prevTopic: prevTopic,
        expectedTopic: expectedTopic,
        mood: mood,
        learnedText: learnedText,
        feedback: feedback,
      );

  group('ClassSession.isActive', () {
    test('returns true when checkOutTime is null', () {
      final session = makeSession();
      expect(session.isActive, isTrue);
    });

    test('returns false when checkOutTime is set', () {
      final session = makeSession(checkOutTime: checkOut);
      expect(session.isActive, isFalse);
    });
  });

  group('ClassSession.toMap', () {
    test('serialises all required fields', () {
      final session = makeSession();
      final map = session.toMap();

      expect(map['id'], 'session-001');
      expect(map['checkInTime'], checkIn.toIso8601String());
      expect(map['checkOutTime'], isNull);
      expect(map['startLat'], 13.7563);
      expect(map['startLng'], 100.5018);
      expect(map['prevTopic'], 'Flutter basics');
      expect(map['expectedTopic'], 'State management');
      expect(map['mood'], 4);
    });

    test('serialises optional fields when provided', () {
      final session = makeSession(
        checkOutTime: checkOut,
        endLat: 13.7600,
        endLng: 100.5100,
        learnedText: 'Learned Provider pattern',
        feedback: 'Great class',
      );
      final map = session.toMap();

      expect(map['checkOutTime'], checkOut.toIso8601String());
      expect(map['endLat'], 13.7600);
      expect(map['endLng'], 100.5100);
      expect(map['learnedText'], 'Learned Provider pattern');
      expect(map['feedback'], 'Great class');
    });
  });

  group('ClassSession.fromMap', () {
    test('roundtrips a complete session', () {
      final original = makeSession(
        checkOutTime: checkOut,
        endLat: 13.76,
        endLng: 100.51,
        learnedText: 'Learned something',
        feedback: 'Good',
      );

      final restored = ClassSession.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.checkInTime, original.checkInTime);
      expect(restored.checkOutTime, original.checkOutTime);
      expect(restored.startLat, original.startLat);
      expect(restored.startLng, original.startLng);
      expect(restored.endLat, original.endLat);
      expect(restored.endLng, original.endLng);
      expect(restored.prevTopic, original.prevTopic);
      expect(restored.expectedTopic, original.expectedTopic);
      expect(restored.mood, original.mood);
      expect(restored.learnedText, original.learnedText);
      expect(restored.feedback, original.feedback);
    });

    test('roundtrips a minimal session with nulls', () {
      final original = makeSession();
      final restored = ClassSession.fromMap(original.toMap());

      expect(restored.checkOutTime, isNull);
      expect(restored.endLat, isNull);
      expect(restored.endLng, isNull);
      expect(restored.learnedText, isNull);
      expect(restored.feedback, isNull);
      expect(restored.isActive, isTrue);
    });

    test('parses lat/lng stored as int (SQLite int coercion)', () {
      final map = {
        'id': 'test-id',
        'checkInTime': checkIn.toIso8601String(),
        'checkOutTime': null,
        'startLat': 14,   // int instead of double
        'startLng': 101,  // int instead of double
        'endLat': null,
        'endLng': null,
        'prevTopic': 'Topic A',
        'expectedTopic': 'Topic B',
        'mood': 3,
        'learnedText': null,
        'feedback': null,
      };

      final session = ClassSession.fromMap(map);
      expect(session.startLat, 14.0);
      expect(session.startLng, 101.0);
    });
  });

  group('ClassSession.copyWith', () {
    test('copies with new checkOut fields', () {
      final original = makeSession();
      final updated = original.copyWith(
        checkOutTime: checkOut,
        endLat: 13.76,
        endLng: 100.51,
        learnedText: 'Learned something',
        feedback: 'Great',
      );

      // Updated fields
      expect(updated.checkOutTime, checkOut);
      expect(updated.endLat, 13.76);
      expect(updated.endLng, 100.51);
      expect(updated.learnedText, 'Learned something');
      expect(updated.feedback, 'Great');
      expect(updated.isActive, isFalse);

      // Unchanged fields preserved
      expect(updated.id, original.id);
      expect(updated.checkInTime, original.checkInTime);
      expect(updated.startLat, original.startLat);
      expect(updated.startLng, original.startLng);
      expect(updated.prevTopic, original.prevTopic);
      expect(updated.expectedTopic, original.expectedTopic);
      expect(updated.mood, original.mood);
    });

    test('does not mutate original session', () {
      final original = makeSession();
      original.copyWith(checkOutTime: checkOut);

      expect(original.checkOutTime, isNull);
      expect(original.isActive, isTrue);
    });
  });

  group('ClassSession mood bounds', () {
    test('accepts boundary mood values 1 and 5', () {
      final low = makeSession(mood: 1);
      final high = makeSession(mood: 5);
      expect(low.mood, 1);
      expect(high.mood, 5);
    });
  });
}
