/// Configuration model for code generation.

import 'converter_config.dart';

/// Configuration for remote config generation.
class GenerationConfig {
  const GenerationConfig({
    required this.inputPath,
    required this.outputPath,
    this.converters = const {},
  });

  final String inputPath;
  final String outputPath;

  /// Map of Remote Config parameter key -> converter configuration.
  final Map<String, ConverterConfig> converters;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenerationConfig &&
        other.inputPath == inputPath &&
        other.outputPath == outputPath &&
        _mapEquals(other.converters, converters);
  }

  @override
  int get hashCode => Object.hash(
    inputPath,
    outputPath,
    Object.hashAllUnordered(
      converters.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );

  @override
  String toString() {
    return 'GenerationConfig('
        'inputPath: $inputPath, '
        'outputPath: $outputPath, '
        'converters: $converters)';
  }

  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
