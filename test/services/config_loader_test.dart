import 'dart:io';
import 'package:test/test.dart';
import 'package:remote_config_gen/src/services/config_loader.dart';
import 'package:remote_config_gen/src/exceptions/remote_config_exception.dart';

void main() {
  group('ConfigLoader', () {
    late Directory tempDir;
    late ConfigLoader configLoader;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('config_loader_test_');
      configLoader = const ConfigLoader();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('loadConfig', () {
      test('loads valid configuration successfully', () {
        final configFile = File('${tempDir.path}/valid_config.yaml');
        configFile.writeAsStringSync('''
input: template.json
output: lib/generated
''');

        final config = configLoader.loadConfig(configFile.path);

        expect(config.inputPath, equals('template.json'));
        expect(config.outputPath, equals('lib/generated'));
      });

      test('throws ConfigurationException when file does not exist', () {
        expect(
          () => configLoader.loadConfig('nonexistent.yaml'),
          throwsA(
            isA<ConfigurationException>().having(
              (e) => e.message,
              'message',
              contains('not found'),
            ),
          ),
        );
      });

      test('throws ConfigurationException when input is missing', () {
        final configFile = File('${tempDir.path}/no_input.yaml');
        configFile.writeAsStringSync('''
output: lib/generated
''');

        expect(
          () => configLoader.loadConfig(configFile.path),
          throwsA(
            isA<ConfigurationException>().having(
              (e) => e.message,
              'message',
              contains('Input path is not set'),
            ),
          ),
        );
      });

      test('throws ConfigurationException when output is missing', () {
        final configFile = File('${tempDir.path}/no_output.yaml');
        configFile.writeAsStringSync('''
input: template.json
''');

        expect(
          () => configLoader.loadConfig(configFile.path),
          throwsA(
            isA<ConfigurationException>().having(
              (e) => e.message,
              'message',
              contains('Output path is not set'),
            ),
          ),
        );
      });

      test('throws ConfigurationException when input is empty', () {
        final configFile = File('${tempDir.path}/empty_input.yaml');
        configFile.writeAsStringSync('''
input: ""
output: lib/generated
''');

        expect(
          () => configLoader.loadConfig(configFile.path),
          throwsA(
            isA<ConfigurationException>().having(
              (e) => e.message,
              'message',
              contains('Input path is not set'),
            ),
          ),
        );
      });

      test('throws ConfigurationException when output is empty', () {
        final configFile = File('${tempDir.path}/empty_output.yaml');
        configFile.writeAsStringSync('''
input: template.json
output: ""
''');

        expect(
          () => configLoader.loadConfig(configFile.path),
          throwsA(
            isA<ConfigurationException>().having(
              (e) => e.message,
              'message',
              contains('Output path is not set'),
            ),
          ),
        );
      });

      test('throws ConfigurationException for invalid YAML', () {
        final configFile = File('${tempDir.path}/invalid.yaml');
        configFile.writeAsStringSync('''
input: template.json
output: lib/generated
  invalid_indent: value
''');

        expect(
          () => configLoader.loadConfig(configFile.path),
          throwsA(
            isA<ConfigurationException>().having(
              (e) => e.message,
              'message',
              contains('Failed to parse YAML'),
            ),
          ),
        );
      });

      test('throws ConfigurationException for non-map YAML', () {
        final configFile = File('${tempDir.path}/non_map.yaml');
        configFile.writeAsStringSync('- item1\n- item2');

        expect(
          () => configLoader.loadConfig(configFile.path),
          throwsA(
            isA<ConfigurationException>().having(
              (e) => e.message,
              'message',
              contains('Invalid configuration file format'),
            ),
          ),
        );
      });

      test('uses default config file when no path provided', () {
        final configFile = File('remote_config_gen.yaml');
        final tempConfigFile = File('${tempDir.path}/remote_config_gen.yaml');

        // Create a temp config and copy it to current directory for test
        tempConfigFile.writeAsStringSync('''
input: default_template.json
output: default_output
''');

        try {
          tempConfigFile.copySync(configFile.path);
          final config = configLoader.loadConfig();

          expect(config.inputPath, equals('default_template.json'));
          expect(config.outputPath, equals('default_output'));
        } finally {
          if (configFile.existsSync()) {
            configFile.deleteSync();
          }
        }
      });

      test('handles file system errors gracefully', () {
        final configFile = File('${tempDir.path}/test.yaml');
        configFile.writeAsStringSync('input: test\noutput: test');

        // Delete the temp directory to cause a filesystem error
        tempDir.deleteSync(recursive: true);

        expect(
          () => configLoader.loadConfig(configFile.path),
          throwsA(
            isA<ConfigurationException>().having(
              (e) => e.message,
              'message',
              contains('not found'),
            ),
          ),
        );
      });
    });
  });
}
