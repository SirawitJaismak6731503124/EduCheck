import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/class_session.dart';

/// Abstracts local storage:
///   - Native (Android / iOS / desktop): SQLite via sqflite
///   - Web (Firebase Hosting):           SharedPreferences (localStorage via JSON)
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;
  static const _webPrefsKey = 'edu_check_sessions';

  static const _createTable = '''
    CREATE TABLE sessions (
      id            TEXT    PRIMARY KEY,
      checkInTime   TEXT    NOT NULL,
      checkOutTime  TEXT,
      startLat      REAL    NOT NULL,
      startLng      REAL    NOT NULL,
      endLat        REAL,
      endLng        REAL,
      prevTopic     TEXT    NOT NULL,
      expectedTopic TEXT    NOT NULL,
      mood          INTEGER NOT NULL,
      learnedText   TEXT,
      feedback      TEXT
    )
  ''';

  Future<void> init() async {
    if (kIsWeb) return; // web path is entirely SharedPreferences-based
    if (_db != null) return;
    final dbPath = join(await getDatabasesPath(), 'edu_check.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) => db.execute(_createTable),
    );
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> insertSession(ClassSession session) async {
    if (kIsWeb) {
      final list = await _webLoad();
      list.add(session.toMap());
      await _webSave(list);
      return;
    }
    await _db!.insert(
      'sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSession(ClassSession session) async {
    if (kIsWeb) {
      final list = await _webLoad();
      final idx = list.indexWhere((m) => m['id'] == session.id);
      if (idx != -1) list[idx] = session.toMap();
      await _webSave(list);
      return;
    }
    await _db!.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  Future<List<ClassSession>> getAllSessions() async {
    if (kIsWeb) {
      final list = await _webLoad();
      return list
          .map(ClassSession.fromMap)
          .toList()
          .reversed
          .toList();
    }
    final rows =
        await _db!.query('sessions', orderBy: 'checkInTime DESC');
    return rows.map(ClassSession.fromMap).toList();
  }

  Future<ClassSession?> getActiveSession() async {
    final all = await getAllSessions();
    try {
      return all.firstWhere((s) => s.isActive);
    } catch (_) {
      return null;
    }
  }

  // ── Web helpers ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _webLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webPrefsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> _webSave(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webPrefsKey, jsonEncode(list));
  }
}
