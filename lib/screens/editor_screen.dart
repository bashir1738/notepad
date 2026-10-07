import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../services/note_store.dart';
import '../utils/formats.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/tags_dialog.dart';

enum _SaveState { idle, saving, saved }

/// Rich text note editor: quill document, debounced autosave,
/// live word count, colors, tags and pinning.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.note});

  final Note note;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final NoteStore _store;
  late Note _note;
  late final QuillController _quill;
  late final TextEditingController _title;

  Timer? _debounce;
  _SaveState _saveState = _SaveState.idle;
  bool _dirty = false;
  bool _closing = false;
  int _words = 0;
  int _chars = 0;

  @override
  void initState() {
    super.initState();
    _store = context.read<NoteStore>();
    _note = widget.note;
    _quill = QuillController(
      document: Document.fromJson(_note.body),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _quill.addListener(_onChanged);
    _title = TextEditingController(text: _note.title)..addListener(_onChanged);
    _updateStats();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_dirty) {
      // Best-effort save if the screen is torn down with pending edits.
      final candidate = _note.copyWith(
        title: _title.text,
        body: _quill.document.toDelta().toJson(),
      );
      if (candidate.isEmptyNote) {
        unawaited(_store.delete(_note.id));
      } else {
        unawaited(_store.save(candidate.copyWith(updatedAt: DateTime.now())));
      }
    }
    _quill.removeListener(_onChanged);
    _quill.dispose();
    _title.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- autosave

  void _onChanged() {
    _dirty = true;
    _updateStats();
    _scheduleSave();
  }

  void _updateStats() {
    final text = Note.plainTextOf(_quill.document.toDelta().toJson()).trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    if (words == _words && text.length == _chars) return;
    setState(() {
      _words = words;
      _chars = text.length;
    });
  }

  void _scheduleSave() {
    if (!mounted) return;
    setState(() => _saveState = _SaveState.saving);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _flush);
  }

  Future<void> _flush() async {
    _debounce?.cancel();
    _debounce = null;
    if (!mounted || !_dirty) return;

    final title = _title.text;
    final body = _quill.document.toDelta().toJson();
    final candidate = _note.copyWith(title: title, body: body);

    if (candidate.isEmptyNote) {
      // Discard notes the user never wrote anything in.
      _dirty = false;
      await _store.delete(_note.id);
      if (mounted) setState(() => _saveState = _SaveState.idle);
      return;
    }

    final updated = candidate.copyWith(updatedAt: DateTime.now());
    await _store.save(updated);
    _note = updated;
    _dirty = false;
    if (mounted) setState(() => _saveState = _SaveState.saved);
  }

  /// Flushes pending edits, then leaves the screen.
  ///
  /// Uses [Navigator.pop] directly: with `PopScope(canPop: false)`,
  /// [Navigator.maybePop] refuses to pop and re-invokes `onPopInvokedWithResult`,
  /// which would loop forever (and freeze the UI).
  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _debounce?.cancel();
    try {
      await _flush();
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  // --------------------------------------------------------------- actions

  void _togglePin() {
    _store.togglePin(_note);
    setState(() {});
  }

  void _showColors() {
    showNoteColorSheet(context: context, note: _note, store: _store)
        .then((_) => setState(() {}));
  }

  void _showTags() {
    showTagsDialog(context: context, store: _store, note: _note)
        .then((_) => setState(() {}));
  }

  void _deleteNote() {
    if (_closing) return;
    _closing = true;
    _debounce?.cancel();
    _dirty = false;
    _store.delete(_note.id);
    if (mounted) Navigator.of(context).pop();
  }

  // ------------------------------------------------------------------ ui

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _close,
          ),
          title: _SaveBadge(state: _saveState),
          actions: [
            IconButton(
              tooltip: _note.isPinned ? 'Unpin note' : 'Pin note',
              icon: Icon(
                _note.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                color: _note.isPinned ? scheme.primary : null,
              ),
              onPressed: _togglePin,
            ),
            PopupMenuButton<String>(
              tooltip: 'Note options',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'color') _showColors();
                if (value == 'tags') _showTags();
                if (value == 'delete') _deleteNote();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'color', child: Text('Color')),
                const PopupMenuItem(value: 'tags', child: Text('Tags')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete note',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.headlineMedium,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Edited ${formatNoteDate(_note.updatedAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.outline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$_words words · $_chars chars',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _TagRow(
                    note: _note,
                    onEdit: _showTags,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 4),
                  const Divider(height: 1),
                ],
              ),
            ),
            Expanded(
              child: QuillEditor.basic(
                controller: _quill,
                config: QuillEditorConfig(
                  placeholder: 'Start writing something beautiful…',
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  scrollPhysics: const BouncingScrollPhysics(),
                  customStyles: _editorStyles(context),
                ),
              ),
            ),
            Material(
              color: theme.scaffoldBackgroundColor,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: QuillSimpleToolbar(
                    controller: _quill,
                    config: QuillSimpleToolbarConfig(
                      multiRowsDisplay: false,
                      showFontFamily: false,
                      showInlineCode: false,
                      showCodeBlock: false,
                      showSubscript: false,
                      showSuperscript: false,
                      showDirection: false,
                      showSearchButton: false,
                      showLineHeightButton: false,
                      showSmallButton: false,
                      color: theme.scaffoldBackgroundColor,
                      iconTheme: QuillIconTheme(
                        iconButtonUnselectedData: IconButtonData(
                          iconSize: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                        iconButtonSelectedData: IconButtonData(
                          iconSize: 20,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Theme-aware quill styles with a comfortable reading rhythm.
  static DefaultStyles _editorStyles(BuildContext context) {
    final base = DefaultStyles.getInstance(context);
    final scheme = Theme.of(context).colorScheme;
    const h = HorizontalSpacing(0, 0);
    const bodySpacing = VerticalSpacing(8, 0);

    final bodyStyle = (base.paragraph?.style ?? const TextStyle()).copyWith(
      fontSize: 16.5,
      height: 1.6,
      letterSpacing: 0.1,
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        bodyStyle,
        h,
        bodySpacing,
        VerticalSpacing.zero,
        null,
      ),
      placeHolder: DefaultTextBlockStyle(
        bodyStyle.copyWith(color: scheme.outline),
        h,
        bodySpacing,
        VerticalSpacing.zero,
        null,
      ),
      h1: base.h1,
      h2: base.h2,
      h3: base.h3,
      h4: base.h4,
      h5: base.h5,
      h6: base.h6,
      lineHeightNormal: base.lineHeightNormal,
      lineHeightTight: base.lineHeightTight,
      lineHeightOneAndHalf: base.lineHeightOneAndHalf,
      lineHeightDouble: base.lineHeightDouble,
      bold: base.bold,
      subscript: base.subscript,
      superscript: base.superscript,
      italic: base.italic,
      small: base.small,
      underline: base.underline,
      strikeThrough: base.strikeThrough,
      inlineCode: base.inlineCode,
      link: base.link,
      color: base.color,
      lists: base.lists,
      quote: base.quote,
      code: base.code,
      indent: base.indent,
      align: base.align,
      leading: base.leading,
      sizeSmall: base.sizeSmall,
      sizeLarge: base.sizeLarge,
      sizeHuge: base.sizeHuge,
      palette: base.palette,
    );
  }
}

// ------------------------------------------------------------ status badge

class _SaveBadge extends StatelessWidget {
  const _SaveBadge({required this.state});

  final _SaveState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      child: switch (state) {
        _SaveState.idle => const SizedBox.shrink(key: ValueKey('idle')),
        _SaveState.saving => Row(
            key: const ValueKey('saving'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Saving…',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.outline),
              ),
            ],
          ),
        _SaveState.saved => Row(
            key: const ValueKey('saved'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Saved',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.primary),
              ),
            ],
          ),
      },
    );
  }
}

// ---------------------------------------------------------------- tag row

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.note,
    required this.onEdit,
    required this.onChanged,
  });

  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tag in note.tags)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('#$tag'),
                      onPressed: onEdit,
                    ),
                  ),
                ActionChip(
                  avatar: Icon(Icons.add_rounded, size: 16, color: scheme.outline),
                  label: Text(
                    note.tags.isEmpty ? 'Add tag' : 'Tag',
                    style: TextStyle(color: scheme.outline),
                  ),
                  onPressed: onEdit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
