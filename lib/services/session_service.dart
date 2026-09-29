import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';

class SessionService {
  static const String _key = 'twist_sessions';

  Future<List<TwistSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final data = jsonDecode(raw);

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map(
            (item) => TwistSession.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSessions(
    List<TwistSession> sessions,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _key,
      jsonEncode(
        sessions.map((e) => e.toJson()).toList(),
      ),
    );
  }
}
