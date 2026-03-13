import 'package:flutter/material.dart';

import '../models/class_session.dart';
import '../services/database_helper.dart';

class SessionProvider extends ChangeNotifier {
  ClassSession? _activeSession;
  List<ClassSession> _sessions = [];
  bool _isLoading = false;

  ClassSession? get activeSession => _activeSession;
  List<ClassSession> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  bool get hasActiveSession => _activeSession != null;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    await DatabaseHelper.instance.init();
    _sessions = await DatabaseHelper.instance.getAllSessions();
    _activeSession = await DatabaseHelper.instance.getActiveSession();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkIn(ClassSession session) async {
    await DatabaseHelper.instance.insertSession(session);
    _activeSession = session;
    _sessions.insert(0, session);
    notifyListeners();
  }

  Future<void> checkOut(ClassSession updated) async {
    await DatabaseHelper.instance.updateSession(updated);
    _activeSession = null;
    final idx = _sessions.indexWhere((s) => s.id == updated.id);
    if (idx != -1) _sessions[idx] = updated;
    notifyListeners();
  }
}
