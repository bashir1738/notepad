import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../services/app_settings.dart';
import '../services/note_store.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/note_card.dart';
import '../widgets/tags_dialog.dart';
import 'editor_screen.dart';

enum _MenuAction { sortUpdated, sortCreated, sortTitle }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';
  String? _tag;
  bool _pinnedOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _tag = null;
      _pinnedOnly = false;
      _searchController.clear();
      _query = '';
      _searching = false;
    });
  }

  Future<void> _createNote() async {
    final note = Note.create();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditorScreen(note: note)),
    );
  }

  Future<void> _openNote(Note note) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditorScreen(note: note)),
    );
  }

  void _deleteNote(Note note) {
    final store = context.read<NoteStore>();
    final index = store.indexOf(note);
    store.delete(note.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Note deleted'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => store.restore(note, index: index),
          ),
        ),
      );
  }

  void _cycleTheme() {
    final settings = context.read<AppSettings>();
    settings.themeMode = switch (settings.themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }

  IconData _themeIcon(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
      };

  String _themeTooltip(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Theme: System',
        ThemeMode.light => 'Theme: Light',
        ThemeMode.dark => 'Theme: Dark',
      };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final store = context.watch<NoteStore>();
    final notes = store.visible(
      query: _query,
      tag: _tag,
      pinnedOnly: _pinnedOnly,
      sort: settings.sort,
    );
    final hasFilters =
        _query.isNotEmpty || _tag != null || _pinnedOnly;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            title: const Text('Notepad'),
            actions: [
              IconButton(
                tooltip: _searching ? 'Close search' : 'Search notes',
                icon: Icon(
                  _searching ? Icons.close_rounded : Icons.search_rounded,
                ),
                onPressed: _toggleSearch,
              ),
              IconButton(
                tooltip: _themeTooltip(settings.themeMode),
                icon: Icon(_themeIcon(settings.themeMode)),
                onPressed: _cycleTheme,
              ),
              PopupMenuButton<_MenuAction>(
                tooltip: 'Sort and options',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (action) {
                  settings.sort = switch (action) {
                    _MenuAction.sortUpdated => NoteSort.updated,
                    _MenuAction.sortCreated => NoteSort.created,
                    _MenuAction.sortTitle => NoteSort.title,
                  };
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      'Sort by',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                  CheckedPopupMenuItem(
                    value: _MenuAction.sortUpdated,
                    checked: settings.sort == NoteSort.updated,
                    child: const Text('Last edited'),
                  ),
                  CheckedPopupMenuItem(
                    value: _MenuAction.sortCreated,
                    checked: settings.sort == NoteSort.created,
                    child: const Text('Date created'),
                  ),
                  CheckedPopupMenuItem(
                    value: _MenuAction.sortTitle,
                    checked: settings.sort == NoteSort.title,
                    child: const Text('Title'),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          if (_searching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Search titles and text…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _FilterRow(
              store: store,
              tag: _tag,
              pinnedOnly: _pinnedOnly,
              onTagSelected: (tag) => setState(() {
                _tag = _tag == tag ? null : tag;
              }),
              onPinnedToggle: () =>
                  setState(() => _pinnedOnly = !_pinnedOnly),
              onAll: _clearFilters,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
              child: Row(
                children: [
                  Text(
                    notes.length == 1 ? '1 note' : '${notes.length} notes',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const Spacer(),
                  if (hasFilters)
                    TextButton(
                      onPressed: _clearFilters,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text('Clear filters'),
                    ),
                ],
              ),
            ),
          ),
          if (notes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                filtered: hasFilters,
                onClearFilters: _clearFilters,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      (constraints.crossAxisExtent / 300).floor().clamp(1, 4);
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: 178,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final note = notes[index];
                        return Dismissible(
                          key: ValueKey(note.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 22),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(
                              Icons.delete_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                          onDismissed: (_) => _deleteNote(note),
                          child: NoteCard(
                            note: note,
                            onTap: () => _openNote(note),
                            onLongPress: () => _showNoteOptions(note),
                          ),
                        );
                      },
                      childCount: notes.length,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNote,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('New note'),
      ),
    );
  }

  // ---------------------------------------------------------------- options

  void _showNoteOptions(Note note) {
    final store = context.read<NoteStore>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.trim().isEmpty
                          ? 'Untitled'
                          : note.title.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'COLOR',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final color in NoteColor.palette)
                          NoteColorDot(
                            color: color,
                            selected: note.colorId == color.id,
                            onTap: () {
                              note.colorId = color.id;
                              store.save(note);
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        note.isPinned
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                      ),
                      title: Text(note.isPinned ? 'Unpin note' : 'Pin note'),
                      onTap: () {
                        store.togglePin(note);
                        Navigator.pop(sheetContext);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.label_outline_rounded),
                      title: const Text('Edit tags'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        showTagsDialog(
                          context: context,
                          store: store,
                          note: note,
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Delete note',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _deleteNote(note);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- filter row

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.store,
    required this.tag,
    required this.pinnedOnly,
    required this.onTagSelected,
    required this.onPinnedToggle,
    required this.onAll,
  });

  final NoteStore store;
  final String? tag;
  final bool pinnedOnly;
  final ValueChanged<String> onTagSelected;
  final VoidCallback onPinnedToggle;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allTags = store.allTags;
    final showAll = tag == null && !pinnedOnly;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ChoiceChip(
            selected: showAll,
            onSelected: (_) => onAll(),
            avatar: Icon(
              Icons.grid_view_rounded,
              size: 16,
              color: showAll ? scheme.onPrimaryContainer : scheme.outline,
            ),
            label: const Text('All'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            selected: pinnedOnly,
            onSelected: (_) => onPinnedToggle(),
            avatar: Icon(
              Icons.push_pin_rounded,
              size: 16,
              color: pinnedOnly ? scheme.onPrimaryContainer : scheme.outline,
            ),
            label: const Text('Pinned'),
          ),
          if (allTags.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 22,
              color: scheme.outlineVariant,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(width: 4),
            for (final t in allTags) ...[
              ChoiceChip(
                selected: tag == t,
                onSelected: (_) => onTagSelected(t),
                label: Text('#$t'),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- empty state

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered, required this.onClearFilters});

  final bool filtered;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                filtered ? Icons.search_off_rounded : Icons.edit_note_rounded,
                size: 44,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              filtered ? 'No matching notes' : 'Your pad is blank',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'Try a different search, or clear the active filters.'
                  : 'Tap “New note” to start writing.\nEverything saves as you type.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (filtered) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onClearFilters,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
