class ClassSession {
  final String id;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double startLat;
  final double startLng;
  final double? endLat;
  final double? endLng;
  final String prevTopic;
  final String expectedTopic;
  final int mood; // 1–5
  final String? learnedText;
  final String? feedback;

  const ClassSession({
    required this.id,
    required this.checkInTime,
    this.checkOutTime,
    required this.startLat,
    required this.startLng,
    this.endLat,
    this.endLng,
    required this.prevTopic,
    required this.expectedTopic,
    required this.mood,
    this.learnedText,
    this.feedback,
  });

  bool get isActive => checkOutTime == null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'checkInTime': checkInTime.toIso8601String(),
        'checkOutTime': checkOutTime?.toIso8601String(),
        'startLat': startLat,
        'startLng': startLng,
        'endLat': endLat,
        'endLng': endLng,
        'prevTopic': prevTopic,
        'expectedTopic': expectedTopic,
        'mood': mood,
        'learnedText': learnedText,
        'feedback': feedback,
      };

  factory ClassSession.fromMap(Map<String, dynamic> map) => ClassSession(
        id: map['id'] as String,
        checkInTime: DateTime.parse(map['checkInTime'] as String),
        checkOutTime: map['checkOutTime'] != null
            ? DateTime.parse(map['checkOutTime'] as String)
            : null,
        startLat: (map['startLat'] as num).toDouble(),
        startLng: (map['startLng'] as num).toDouble(),
        endLat: map['endLat'] != null ? (map['endLat'] as num).toDouble() : null,
        endLng: map['endLng'] != null ? (map['endLng'] as num).toDouble() : null,
        prevTopic: map['prevTopic'] as String,
        expectedTopic: map['expectedTopic'] as String,
        mood: map['mood'] as int,
        learnedText: map['learnedText'] as String?,
        feedback: map['feedback'] as String?,
      );

  ClassSession copyWith({
    DateTime? checkOutTime,
    double? endLat,
    double? endLng,
    String? learnedText,
    String? feedback,
  }) =>
      ClassSession(
        id: id,
        checkInTime: checkInTime,
        checkOutTime: checkOutTime ?? this.checkOutTime,
        startLat: startLat,
        startLng: startLng,
        endLat: endLat ?? this.endLat,
        endLng: endLng ?? this.endLng,
        prevTopic: prevTopic,
        expectedTopic: expectedTopic,
        mood: mood,
        learnedText: learnedText ?? this.learnedText,
        feedback: feedback ?? this.feedback,
      );
}
