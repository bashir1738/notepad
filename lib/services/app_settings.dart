import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'note_store.dart';

/// Persisted user preferences (theme mode, default sort).
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._themeMode, this._sort);

  final SharedPreferences _prefs;
  ThemeMode _themeMode;
  NoteSort _sort;

  static const String _storageKey = 'settings_v1';

  static Future<AppSettings> open() async {
    final prefs = await SharedPreferences.getInstance();
    var themeMode = ThemeMode.system;
    var sort = NoteSort.updated;
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        themeMode = switch (decoded['themeMode'] as String?) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        sort = switch (decoded['sort'] as String?) {
          'created' => NoteSort.created,
          'title' => NoteSort.title,
          _ => NoteSort.updated,
        };
      } catch (_) {
        // Fall back to defaults.
      }
    }
    return AppSettings._(prefs, themeMode, sort);
  }

  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    if (value == _themeMode) return;
    _themeMode = value;
    _persist();
    notifyListeners();
  }

  NoteSort get sort => _sort;
  set sort(NoteSort value) {
    if (value == _sort) return;
    _sort = value;
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _prefs.setString(_storageKey, jsonEncode({
      'themeMode': switch (_themeMode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
      'sort': switch (_sort) {
        NoteSort.updated => 'updated',
        NoteSort.created => 'created',
        NoteSort.title => 'title',
      },
    }));
  }
}
