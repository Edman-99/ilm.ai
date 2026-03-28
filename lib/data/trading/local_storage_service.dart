import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Локальное хранилище для credentials и dashboard layout.
class LocalStorageService {
  static const _emailKey = 'trading_email';
  static const _passwordKey = 'trading_password';
  static const _layoutKey = 'dashboard_layout';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // ── Credentials ──

  static Future<void> saveCredentials(String email, String password) async {
    final prefs = await _prefs;
    await prefs.setString(_emailKey, email);
    await prefs.setString(_passwordKey, password);
  }

  static Future<({String email, String password})?> loadCredentials() async {
    final prefs = await _prefs;
    final email = prefs.getString(_emailKey);
    final password = prefs.getString(_passwordKey);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  static Future<void> clearCredentials() async {
    final prefs = await _prefs;
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
  }

  // ── Dashboard layout ──

  /// Saves ordered list of widget IDs + their column spans.
  /// Format: [ { "id": "equity_curve", "span": 3 }, ... ]
  static Future<void> saveLayout(List<DashboardTile> tiles) async {
    final prefs = await _prefs;
    final json = tiles.map((t) => {'id': t.id, 'span': t.span}).toList();
    await prefs.setString(_layoutKey, jsonEncode(json));
  }

  static Future<List<DashboardTile>?> loadLayout() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_layoutKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) {
        final map = e as Map<String, dynamic>;
        return DashboardTile(
          id: map['id'] as String,
          span: map['span'] as int? ?? 1,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearLayout() async {
    final prefs = await _prefs;
    await prefs.remove(_layoutKey);
  }
}

/// Represents one tile in the dashboard grid.
class DashboardTile {
  DashboardTile({required this.id, this.span = 1});

  final String id;
  int span; // 1 = 1/3, 2 = 2/3, 3 = full width
}
