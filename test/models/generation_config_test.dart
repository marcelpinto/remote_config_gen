import 'package:test/test.dart';
import 'package:remote_config_gen/src/models/generation_config.dart';

void main() {
  group('GenerationConfig', () {
    test('creates config with paths', () {
      const config = GenerationConfig(
        inputPath: 'input/template.json',
        outputPath: 'lib/generated',
      );

      expect(config.inputPath, equals('input/template.json'));
      expect(config.outputPath, equals('lib/generated'));
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

    test('toString works correctly', () {
      const config = GenerationConfig(
        inputPath: 'input/template.json',
        outputPath: 'lib/generated',
      );

      final result = config.toString();
      expect(result, contains('input/template.json'));
      expect(result, contains('lib/generated'));
    });
  });
}
