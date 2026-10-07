import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

enum NoteSort { updated, created, title }

extension NoteSortLabel on NoteSort {
  String get label => switch (this) {
        NoteSort.updated => 'Last edited',
        NoteSort.created => 'Date created',
        NoteSort.title => 'Title',
      };
}

/// Owns the note collection and persists it as JSON in local storage.
class NoteStore extends ChangeNotifier {
  NoteStore._(this._prefs, this._notes);

  final SharedPreferences _prefs;
  final List<Note> _notes;

  static const String _storageKey = 'notes_v1';

  static Future<NoteStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    final notes = <Note>[];
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            notes.add(Note.fromJson(item));
          }
        }
      } catch (_) {
        // Corrupted storage: start with a clean slate instead of crashing.
      }
    }
    return NoteStore._(prefs, notes);
  }

  List<Note> get notes => List.unmodifiable(_notes);

  int get count => _notes.length;

  int get pinnedCount => _notes.where((n) => n.isPinned).length;

  /// Every tag in use, alphabetically, for the filter row.
  List<String> get allTags {
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    final sorted = tags.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  int indexOf(Note note) => _notes.indexWhere((n) => n.id == note.id);

  Note? byId(String id) {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  /// Adds the note, or updates it in place if it already exists.
  /// Does not bump [Note.updatedAt]; callers decide that.
  Future<void> save(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.insert(0, note);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _persist();
    notifyListeners();
  }

  /// Puts a previously deleted note back (used by the undo snackbar).
  Future<void> restore(Note note, {int? index}) async {
    if (byId(note.id) != null) return;
    final target = (index ?? _notes.length).clamp(0, _notes.length);
    _notes.insert(target, note);
    await _persist();
    notifyListeners();
  }

  Future<void> togglePin(Note note) async {
    note.isPinned = !note.isPinned;
    await _persist();
    notifyListeners();
  }

  /// Filters and sorts notes for display. Pinned notes always float on top.
  List<Note> visible({
    String query = '',
    String? tag,
    bool pinnedOnly = false,
    NoteSort sort = NoteSort.updated,
  }) {
    final q = query.trim().toLowerCase();
    final result = _notes.where((n) {
      if (pinnedOnly && !n.isPinned) return false;
      if (tag != null && !n.tags.contains(tag)) return false;
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) ||
          n.plainText.toLowerCase().contains(q);
    }).toList();

    result.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return switch (sort) {
        NoteSort.updated => b.updatedAt.compareTo(a.updatedAt),
        NoteSort.created => b.createdAt.compareTo(a.createdAt),
        NoteSort.title => _compareTitles(a, b),
      };
    });
    return result;
  }

  static int _compareTitles(Note a, Note b) {
    final at = a.title.trim().toLowerCase();
    final bt = b.title.trim().toLowerCase();
    if (at.isEmpty && bt.isEmpty) return 0;
    if (at.isEmpty) return 1;
    if (bt.isEmpty) return -1;
    return at.compareTo(bt);
  }

  Future<void> _persist() async {
    final encoded =
        jsonEncode(_notes.map((n) => n.toJson()).toList(growable: false));
    await _prefs.setString(_storageKey, encoded);
  }
}
