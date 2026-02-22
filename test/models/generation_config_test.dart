import 'package:test/test.dart';
import 'package:remote_config_gen/src/models/generation_config.dart';
import 'package:remote_config_gen/src/models/converter_config.dart';

void main() {
  group('GenerationConfig', () {
    test('creates config with paths', () {
      const config = GenerationConfig(
        inputPath: 'input/template.json',
        outputPath: 'lib/generated',
      );

      expect(config.inputPath, equals('input/template.json'));
      expect(config.outputPath, equals('lib/generated'));
      expect(config.converters, isEmpty);
    });

    test('creates config with converters', () {
      final config = GenerationConfig(
        inputPath: 'template.json',
        outputPath: 'lib/generated',
        converters: {
          'theme_config': const ConverterConfig(
            paramKey: 'theme_config',
            type: 'ThemeConfig',
            converter: 'ThemeConfigConverter',
            import: 'package:app/theme.dart',
          ),
        },
      );

      expect(config.converters, hasLength(1));
      expect(config.converters['theme_config']!.type, equals('ThemeConfig'));
    });

    test('equality works correctly', () {
      const config1 = GenerationConfig(
        inputPath: 'input/template.json',
        outputPath: 'lib/generated',
      );
      const config2 = GenerationConfig(
        inputPath: 'input/template.json',
        outputPath: 'lib/generated',
      );
      const config3 = GenerationConfig(
        inputPath: 'different/template.json',
        outputPath: 'lib/generated',
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('equality considers converters', () {
      final config1 = GenerationConfig(
        inputPath: 'template.json',
        outputPath: 'lib/generated',
        converters: {
          'key': const ConverterConfig(
            paramKey: 'key',
            type: 'T',
            converter: 'TC',
            import: 'p.dart',
          ),
        },
      );
      const config2 = GenerationConfig(
        inputPath: 'template.json',
        outputPath: 'lib/generated',
      );

      expect(config1, isNot(equals(config2)));
    });

    test('equal converter maps have matching hashCode', () {
      const converter = ConverterConfig(
        paramKey: 'key',
        type: 'T',
        converter: 'TC',
        import: 'p.dart',
      );
      final config1 = GenerationConfig(
        inputPath: 'template.json',
        outputPath: 'lib/generated',
        converters: {'key': converter},
      );
      final config2 = GenerationConfig(
        inputPath: 'template.json',
        outputPath: 'lib/generated',
        converters: Map<String, ConverterConfig>.from({'key': converter}),
      );

      expect(config1, equals(config2));
      expect(identical(config1.converters, config2.converters), isFalse);
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('toString works correctly', () {
      const config = GenerationConfig(
        inputPath: 'input/template.json',
        outputPath: 'lib/generated',
      );

      final result = config.toString();
      expect(result, contains('input/template.json'));
      expect(result, contains('lib/generated'));
      expect(result, contains('converters'));
    });
  });
}
