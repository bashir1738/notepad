import 'package:flutter/material.dart';

/// A named accent color that can be assigned to a note.
class NoteColor {
  const NoteColor(this.id, this.label, this.color);

  final String id;
  final String label;
  final Color color;

  static const List<NoteColor> palette = [
    NoteColor('indigo', 'Indigo', Color(0xFF6366F1)),
    NoteColor('violet', 'Violet', Color(0xFF8B5CF6)),
    NoteColor('rose', 'Rose', Color(0xFFF43F5E)),
    NoteColor('amber', 'Amber', Color(0xFFF59E0B)),
    NoteColor('emerald', 'Emerald', Color(0xFF10B981)),
    NoteColor('teal', 'Teal', Color(0xFF14B8A6)),
    NoteColor('sky', 'Sky', Color(0xFF0EA5E9)),
    NoteColor('graphite', 'Graphite', Color(0xFF64748B)),
  ];

  static NoteColor byId(String id) {
    for (final c in palette) {
      if (c.id == id) return c;
    }
    return palette.first;
  }
}

/// A single note. The body is stored as a Quill delta (JSON), so the rich
/// formatting survives round-trips through storage.
class Note {
  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.colorId,
    required this.tags,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.create() {
    final now = DateTime.now();
    return Note(
      id: 'note_${now.microsecondsSinceEpoch}',
      title: '',
      body: <dynamic>[
        {'insert': '\n'}
      ],
      colorId: 'indigo',
      tags: <String>[],
      isPinned: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as List<dynamic>?) ?? <dynamic>[
        {'insert': '\n'}
      ],
      colorId: (json['colorId'] as String?) ?? 'indigo',
      tags: ((json['tags'] as List<dynamic>?) ?? const []).cast<String>(),
      isPinned: (json['isPinned'] as bool?) ?? false,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  String title;
  List<dynamic> body;
  String colorId;
  List<String> tags;
  bool isPinned;
  final DateTime createdAt;
  DateTime updatedAt;

  NoteColor get color => NoteColor.byId(colorId);

  /// Extracts plain text from a Quill delta without needing an editor.
  static String plainTextOf(List<dynamic> delta) {
    final buffer = StringBuffer();
    for (final op in delta) {
      if (op is Map) {
        final insert = op['insert'];
        if (insert is String) buffer.write(insert);
      }
    }
    return buffer.toString();
  }

  String get plainText => plainTextOf(body);

  /// Trimmed body text, used for previews and search.
  String get preview => plainText.trim();

  int get wordCount {
    final text = preview;
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  int get characterCount => preview.length;

  bool get isEmptyNote => title.trim().isEmpty && preview.isEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'colorId': colorId,
      'tags': tags,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Note copyWith({
    String? title,
    List<dynamic>? body,
    String? colorId,
    List<String>? tags,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      colorId: colorId ?? this.colorId,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
