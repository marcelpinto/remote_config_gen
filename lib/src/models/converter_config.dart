/// Configuration for a JSON converter mapping.
class ConverterConfig {
  const ConverterConfig({
    required this.paramKey,
    required this.type,
    required this.converter,
    required this.import,
  });

  /// The Remote Config parameter key this converter applies to.
  final String paramKey;

  /// The generic type T (e.g. `ThemeConfig`).
  final String type;

  /// The converter class name (e.g. `ThemeConfigConverter`).
  final String converter;

  /// The Dart import for both the type and converter (e.g. `package:my_app/models/theme.dart`).
  final String import;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConverterConfig &&
        other.paramKey == paramKey &&
        other.type == type &&
        other.converter == converter &&
        other.import == import;
  }

  @override
  int get hashCode => Object.hash(paramKey, type, converter, import);

  @override
  String toString() {
    return 'ConverterConfig('
        'paramKey: $paramKey, '
        'type: $type, '
        'converter: $converter, '
        'import: $import)';
  }
}
