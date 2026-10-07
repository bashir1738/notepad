const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// Human-friendly timestamp used on cards and in the editor:
/// "just now" · "12 min ago" · "Today, 14:32" · "Yesterday" · "Oct 3" · "Oct 3, 2025"
String formatNoteDate(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';

  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final days = today.difference(day).inDays;

  if (days == 0) return 'Today, ${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
  if (days == 1) return 'Yesterday';

  final month = _months[time.month - 1];
  if (time.year == now.year) return '$month ${time.day}';
  return '$month ${time.day}, ${time.year}';
}
