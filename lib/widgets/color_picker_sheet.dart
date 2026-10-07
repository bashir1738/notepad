import 'package:flutter/material.dart';

import '../models/note.dart';
import '../services/note_store.dart';

/// Round accent-color selector used in sheets and menus.
class NoteColorDot extends StatelessWidget {
  const NoteColorDot({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final NoteColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: color.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.color,
            shape: BoxShape.circle,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.color.withValues(alpha: 0.55),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: selected
              ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

/// Bottom sheet for picking a note's accent color.
Future<void> showNoteColorSheet({
  required BuildContext context,
  required Note note,
  required NoteStore store,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Note color', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Colors make notes easy to spot in the grid.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Done'),
                    ),
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
