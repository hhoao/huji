/// Parses YOLO ONNX custom metadata (Python dict literal in `names` field).
class YoloOnnxMetadata {
  YoloOnnxMetadata._();

  /// Parse `{0: 'fire_ball', ...}` into ordered class names.
  /// Returns null when [namesLiteral] is empty or unparseable.
  static List<String>? tryParseClassNames(String namesLiteral) {
    if (namesLiteral.trim().isEmpty || namesLiteral.trim() == '{}') {
      return null;
    }
    try {
      return parseClassNames(namesLiteral);
    } on FormatException {
      return null;
    }
  }

  /// Parse `{0: 'fire_ball', 1: 'pick_ball', ...}` into ordered class names.
  static List<String> parseClassNames(String namesLiteral) {
    final entries = <int, String>{};
    for (final match
        in RegExp(r"(\d+)\s*:\s*'([^']+)'").allMatches(namesLiteral)) {
      entries[int.parse(match.group(1)!)] = match.group(2)!;
    }
    if (entries.isEmpty) {
      throw FormatException('Unable to parse YOLO class names: $namesLiteral');
    }
    final indices = entries.keys.toList()..sort();
    return indices.map((i) => entries[i]!).toList();
  }
}
