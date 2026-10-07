import 'package:flutter/material.dart';

import '../models/note.dart';
import '../services/note_store.dart';

/// Dialog for editing a note's tags, with suggestions from other notes.
Future<void> showTagsDialog({
  required BuildContext context,
  required NoteStore store,
  required Note note,
}) {
  final controller = TextEditingController();

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      var tags = List<String>.from(note.tags);

      void addTag(String raw) {
        final tag = raw.trim();
        if (tag.isEmpty) return;
        final exists = tags.any((t) => t.toLowerCase() == tag.toLowerCase());
        if (!exists) tags = [...tags, tag];
        controller.clear();
      }

      return StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final suggestions =
              store.allTags.where((t) => !tags.contains(t)).toList();

          return AlertDialog(
            title: const Text('Tags'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tags.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No tags yet — add one below.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in tags)
                            Chip(
                              label: Text(tag),
                              deleteIcon:
                                  const Icon(Icons.close_rounded, size: 16),
                              onDeleted: () => setDialogState(
                                () => tags =
                                    tags.where((t) => t != tag).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (suggestions.isNotEmpty) ...[
                    Text(
                      'SUGGESTIONS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in suggestions)
                          ActionChip(
                            label: Text(tag),
                            onPressed: () =>
                                setDialogState(() => tags = [...tags, tag]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: controller,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Add a tag'),
                    onSubmitted: (value) =>
                        setDialogState(() => addTag(value)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  note.tags = tags;
                  store.save(note);
                  Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(controller.dispose);
}
