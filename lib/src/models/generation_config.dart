/// Configuration model for code generation.

import 'converter_config.dart';
import 'default_override.dart';

/// Configuration for remote config generation.
class GenerationConfig {
  const GenerationConfig({
    required this.inputPath,
    required this.outputPath,
    this.converters = const {},
    this.defaultOverrides = const [],
    this.defaultParseWarnings = const [],
  });

  final String inputPath;
  final String outputPath;

  /// Map of Remote Config parameter key -> converter configuration.
  final Map<String, ConverterConfig> converters;

  /// Default value overrides from the `defaults` section (boolean params only).
  final List<DefaultOverride> defaultOverrides;

  /// Warnings from parsing the `defaults` section (e.g. non-boolean ignored).
  final List<String> defaultParseWarnings;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenerationConfig &&
        other.inputPath == inputPath &&
        other.outputPath == outputPath &&
        _mapEquals(other.converters, converters) &&
        _listEquals(other.defaultOverrides, defaultOverrides) &&
        _listEquals(other.defaultParseWarnings, defaultParseWarnings);
  }

  @override
  int get hashCode => Object.hash(
    inputPath,
    outputPath,
    Object.hashAllUnordered(
      converters.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    defaultOverrides,
    defaultParseWarnings,
  );

  @override
  String toString() {
    return 'GenerationConfig('
        'inputPath: $inputPath, '
        'outputPath: $outputPath, '
        'converters: $converters, '
        'defaultOverrides: $defaultOverrides)';
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
