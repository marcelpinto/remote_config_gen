import 'package:test/test.dart';
import 'package:remote_config_gen/src/models/converter_config.dart';

void main() {
  group('ConverterConfig', () {
    test('creates config with all fields', () {
      const config = ConverterConfig(
        paramKey: 'theme_config',
        type: 'ThemeConfig',
        converter: 'ThemeConfigConverter',
        import: 'package:my_app/models/theme.dart',
      );

      expect(config.paramKey, equals('theme_config'));
      expect(config.type, equals('ThemeConfig'));
      expect(config.converter, equals('ThemeConfigConverter'));
      expect(config.import, equals('package:my_app/models/theme.dart'));
    });

    test('equality works correctly', () {
      const config1 = ConverterConfig(
        paramKey: 'theme_config',
        type: 'ThemeConfig',
        converter: 'ThemeConfigConverter',
        import: 'package:my_app/models/theme.dart',
      );
      const config2 = ConverterConfig(
        paramKey: 'theme_config',
        type: 'ThemeConfig',
        converter: 'ThemeConfigConverter',
        import: 'package:my_app/models/theme.dart',
      );
      const config3 = ConverterConfig(
        paramKey: 'other_config',
        type: 'OtherConfig',
        converter: 'OtherConverter',
        import: 'package:my_app/models/other.dart',
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('toString works correctly', () {
      const config = ConverterConfig(
        paramKey: 'theme_config',
        type: 'ThemeConfig',
        converter: 'ThemeConfigConverter',
        import: 'package:my_app/models/theme.dart',
      );

      final result = config.toString();
      expect(result, contains('theme_config'));
      expect(result, contains('ThemeConfig'));
      expect(result, contains('ThemeConfigConverter'));
      expect(result, contains('package:my_app/models/theme.dart'));
    });
  });
}
