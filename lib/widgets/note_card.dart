import 'package:flutter/material.dart';

import '../models/note.dart';
import '../utils/formats.dart';

/// A single note preview in the home grid: tinted card, title, snippet,
/// tags and a relative timestamp.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = note.color.color;

    final background = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.17 : 0.10),
      isDark ? scheme.surfaceContainerLow : Colors.white,
    );

    final title = note.title.trim();
    final snippet = note.preview;
    final tags = note.tags.take(2).toList();

    return Material(
      color: background,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: accent.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (note.isPinned)
                    Icon(
                      Icons.push_pin_rounded,
                      size: 16,
                      color: accent,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title.isEmpty ? 'Untitled' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: title.isEmpty ? scheme.outline : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Text(
                  snippet.isEmpty ? 'Empty note' : snippet,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final tag in tags) ...[
                    _MiniTag(tag: tag, accent: accent),
                    const SizedBox(width: 6),
                  ],
                  if (note.tags.length > 2) ...[
                    Text(
                      '+${note.tags.length - 2}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Spacer(),
                  Text(
                    formatNoteDate(note.updatedAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.outline,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.tag, required this.accent});

  final String tag;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#$tag',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
