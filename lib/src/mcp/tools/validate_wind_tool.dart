import '../mcp_server.dart';

/// Validate Wind MCP Tool.
///
/// Validates Wind UI utility class strings for correctness.
/// Checks for valid patterns like bg-red-500, p-4, flex, etc.
class ValidateWindTool extends McpTool {
  @override
  String get description =>
      'Validate Wind UI utility classes. Returns invalid classes if any. '
      'Use this to verify className strings before using them.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'className': {
            'type': 'string',
            'description': 'Space-separated Wind utility classes to validate',
          },
        },
        'required': ['className'],
      };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final className = arguments['className'] as String? ?? '';
    if (className.trim().isEmpty) {
      return 'No classes provided.';
    }

    final classes = className.split(RegExp(r'\s+')).where((c) => c.isNotEmpty);
    final invalid = <String>[];
    final valid = <String>[];

    for (final cls in classes) {
      if (_isValidWindClass(cls)) {
        valid.add(cls);
      } else {
        invalid.add(cls);
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('# Wind Validation Result');
    buffer.writeln();
    buffer.writeln('**Total:** ${classes.length} classes');
    buffer.writeln('**Valid:** ${valid.length}');
    buffer.writeln('**Invalid:** ${invalid.length}');

    if (invalid.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## Invalid Classes');
      for (final cls in invalid) {
        buffer.writeln('- `$cls`');
      }
    }

    return buffer.toString();
  }

  bool _isValidWindClass(String cls) {
    // Remove state prefix (hover:, focus:, etc.)
    var className = cls;
    final prefixPattern = RegExp(
        r'^(hover|focus|active|disabled|loading|checked|error|sm|md|lg|xl|dark):');
    while (prefixPattern.hasMatch(className)) {
      className = className.replaceFirst(prefixPattern, '');
    }

    // Valid Wind patterns
    final patterns = [
      // Layout
      RegExp(
          r'^(flex|flex-row|flex-col|grid|wrap|block|hidden|inline|inline-flex)$'),
      RegExp(r'^flex-(1|auto|none|grow|shrink)$'),
      RegExp(r'^grid-cols-(\d+|none)$'),
      RegExp(
          r'^(justify|items|self|content)-(start|end|center|between|around|evenly|stretch|baseline)$'),

      // Sizing
      RegExp(
          r'^(w|h|min-w|max-w|min-h|max-h)-(\d+|full|screen|auto|1\/2|1\/3|2\/3|1\/4|3\/4|\[\d+px\])$'),
      RegExp(r'^aspect-(auto|square|video)$'),

      // Spacing
      RegExp(
          r'^(p|px|py|pt|pr|pb|pl|m|mx|my|mt|mr|mb|ml|gap|gap-x|gap-y|space-x|space-y)-(\d+|auto|\[\d+px\])$'),

      // Typography
      RegExp(r'^text-(xs|sm|base|lg|xl|2xl|3xl|4xl|5xl|6xl)$'),
      RegExp(
          r'^font-(thin|light|normal|medium|semibold|bold|extrabold|black)$'),
      RegExp(r'^text-(left|center|right|justify)$'),
      RegExp(
          r'^(uppercase|lowercase|capitalize|italic|truncate|underline|line-through)$'),
      RegExp(r'^line-clamp-(\d+)$'),

      // Colors
      RegExp(r'^(text|bg|border|ring)-(transparent|white|black|current)$'),
      RegExp(
          r'^(text|bg|border|ring|fill|stroke)-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose|primary)(-(\d+))?(/\d+)?$'),
      RegExp(r'^(text|bg|border)-\[#[0-9A-Fa-f]{3,6}\]$'),

      // Borders & Effects
      RegExp(r'^border(-\d+|-t|-r|-b|-l)?$'),
      RegExp(r'^rounded(-(none|sm|md|lg|xl|2xl|full|t|r|b|l|tl|tr|br|bl))?$'),
      RegExp(r'^shadow(-(none|sm|md|lg|xl|2xl))?$'),
      RegExp(r'^ring(-\d+)?$'),
      RegExp(r'^opacity-(\d+)$'),

      // Animation
      RegExp(r'^duration-(\d+)$'),
      RegExp(r'^ease-(linear|in|out|in-out)$'),
      RegExp(r'^animate-(none|spin|pulse|bounce|ping)$'),

      // Object fit
      RegExp(r'^object-(contain|cover|fill|none|scale-down)$'),

      // Overflow
      RegExp(
          r'^overflow-(auto|hidden|visible|scroll|x-auto|y-auto|x-hidden|y-hidden)$'),
    ];

    return patterns.any((p) => p.hasMatch(className));
  }
}
