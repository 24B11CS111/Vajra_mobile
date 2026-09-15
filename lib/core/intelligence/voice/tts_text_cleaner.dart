/// Utility for cleaning and preparing assistant response text before passing
/// to the native Text-to-Speech engine.
///
/// Strips UI Markdown formatting, code blocks, technical JSON payloads,
/// and bullet symbols while preserving natural sentence structure and meaning.
class TtsTextCleaner {
  TtsTextCleaner._();

  /// Cleans the input [text] for natural, fluent spoken output.
  static String clean(String text) {
    if (text.trim().isEmpty) return '';

    String cleaned = text;

    // 1. Remove streaming artifacts (e.g. cursor block)
    cleaned = cleaned.replaceAll('▌', '');

    // 2. Remove fenced code blocks (```code```) entirely to avoid reading raw syntax
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), '');

    // 3. Normalize inline code (`code` -> code)
    cleaned = cleaned.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) {
      return match.group(1) ?? '';
    });

    // 4. Remove technical JSON / tool payloads e.g. {"tool": ...} or {"action": ...}
    cleaned = cleaned.replaceAll(
      RegExp(r'\{[\s\r\n]*"(?:tool|action|status|error|code|intent|payload)"[\s\S]*?\}'),
      '',
    );

    // 5. Remove HTML/XML tags
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');

    // 6. Remove image references ![alt](url) before processing links
    cleaned = cleaned.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), '');

    // 7. Convert Markdown links [title](url) -> title
    cleaned = cleaned.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (match) {
      return match.group(1) ?? '';
    });

    // 8. Process line by line for headers, bullets, and blockquotes
    final lines = cleaned.split(RegExp(r'\r?\n'));
    final processedLines = <String>[];

    for (var line in lines) {
      var trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Remove horizontal rules (---, ***, ___)
      if (RegExp(r'^[-*_]{3,}$').hasMatch(trimmed)) {
        continue;
      }

      // Remove blockquotes (> quote)
      if (trimmed.startsWith('>')) {
        trimmed = trimmed.replaceFirst(RegExp(r'^>\s*'), '').trim();
      }

      // Convert Markdown headers (### Header -> Header.)
      if (trimmed.startsWith('#')) {
        trimmed = trimmed.replaceFirst(RegExp(r'^#+\s*'), '').trim();
        if (trimmed.isNotEmpty && !_endsInPunctuation(trimmed)) {
          trimmed = '$trimmed.';
        }
      }

      // Strip bullet points (- item, * item, + item)
      if (RegExp(r'^[-*+]\s+').hasMatch(trimmed)) {
        trimmed = trimmed.replaceFirst(RegExp(r'^[-*+]\s+'), '').trim();
        if (trimmed.isNotEmpty && !_endsInPunctuation(trimmed)) {
          trimmed = '$trimmed.';
        }
      }

      // Strip numbered list markers (1. item, 2) item)
      if (RegExp(r'^\d+[\.)]\s+').hasMatch(trimmed)) {
        trimmed = trimmed.replaceFirst(RegExp(r'^\d+[\.)]\s+'), '').trim();
        if (trimmed.isNotEmpty && !_endsInPunctuation(trimmed)) {
          trimmed = '$trimmed.';
        }
      }

      if (trimmed.isNotEmpty) {
        processedLines.add(trimmed);
      }
    }

    cleaned = processedLines.join(' ');

    // 9. Remove bold, italics, strikethrough markdown
    cleaned = cleaned.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m.group(1) ?? '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m.group(1) ?? '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'~~([^~]+)~~'), (m) => m.group(1) ?? '');

    // 10. Clean up multiple punctuation and whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\.\s*\.'), '.');
    cleaned = cleaned.replaceAllMapped(RegExp(r'\s+([.,!?:;])'), (m) => m.group(1) ?? '');

    return cleaned.trim();
  }

  static bool _endsInPunctuation(String s) {
    if (s.isEmpty) return false;
    final last = s[s.length - 1];
    return last == '.' || last == '!' || last == '?' || last == ':' || last == ';';
  }
}
