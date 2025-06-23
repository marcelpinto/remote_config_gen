import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:remote_config_gen/src/remote_config_generator.dart';
import 'package:remote_config_gen/src/exceptions/remote_config_exception.dart';

void main() {
  group('RemoteConfigGenerator Integration Tests', () {
    late Directory tempDir;
    late RemoteConfigGenerator generator;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('integration_test_');
      generator = const RemoteConfigGenerator();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('generateFromPaths', () {
      test('generates complete remote config code successfully', () async {
        // Create a comprehensive template
        final template = {
          'welcome_message': 'Welcome to our app!',
          'feature_flag': true,
          'max_retry_count': 3.0,
          'api_config': '{"timeout": 30, "retries": 3}',
          'parameters': {
            'welcome_message': {
              'valueType': 'STRING',
              'description': 'Welcome message for users',
              'defaultValue': {'useInAppDefault': true},
            },
            'feature_enabled': {
              'valueType': 'BOOLEAN',
              'description': 'Enable new feature',
              'defaultValue': {'value': false},
            },
            'max_retry_count': {
              'valueType': 'NUMBER',
              'description': 'Maximum retry attempts',
              'defaultValue': {'useInAppDefault': true},
            },
            'api_config': {
              'valueType': 'JSON',
              'description': 'API configuration',
              'defaultValue': {'useInAppDefault': true},
            },
          },
          'parameterGroups': {
            'ui_settings': {
              'description': 'User interface settings',
              'parameters': {
                'primary_color': {
                  'valueType': 'STRING',
                  'description': 'Primary UI color',
                  'defaultValue': {'value': '#007AFF'},
                },
                'animation_duration': {
                  'valueType': 'NUMBER',
                  'description': 'Animation duration in ms',
                  'defaultValue': {'value': 300.0},
                },
              },
            },
            'api_settings': {
              'description': 'API related settings',
              'parameters': {
                'base_url': {
                  'valueType': 'STRING',
                  'description': 'API base URL',
                  'defaultValue': {'value': 'https://api.example.com'},
                },
                'enable_logging': {
                  'valueType': 'BOOLEAN',
                  'description': 'Enable API logging',
                  'defaultValue': {'value': false},
                },
              },
            },
          },
        };

        // Write template file
        final templateFile = File('${tempDir.path}/template.json');
        await templateFile.writeAsString(json.encode(template));

        // Generate code
        await generator.generateFromPaths(
          templatePath: templateFile.path,
          outputPath: '${tempDir.path}/output',
        );

        // Verify output file exists
        final outputFile = File(
          '${tempDir.path}/output/remote_config_params.gen.dart',
        );
        expect(outputFile.existsSync(), isTrue);

        // Read and verify generated content
        final generatedContent = await outputFile.readAsString();

        // Check basic structure
        expect(
          generatedContent,
          contains(
            'import \'package:firebase_remote_config/firebase_remote_config.dart\';',
          ),
        );
        expect(generatedContent, contains('class RemoteConfigParam<T>'));
        expect(generatedContent, contains('class RemoteConfigParams'));
        expect(generatedContent, contains('const RemoteConfigParams._();'));

        // Check main parameters
        expect(
          generatedContent,
          contains('static const RemoteConfigParam<String> welcomeMessage'),
        );
        expect(
          generatedContent,
          contains('static const RemoteConfigParam<bool> featureEnabled'),
        );
        expect(
          generatedContent,
          contains('static const RemoteConfigParam<double> maxRetryCount'),
        );
        expect(
          generatedContent,
          contains('static const RemoteConfigParam<String> apiConfig'),
        );

        // Check parameter groups
        expect(generatedContent, contains('class UiSettings'));
        expect(generatedContent, contains('class ApiSettings'));
        expect(
          generatedContent,
          contains('static const UiSettings uiSettings'),
        );
        expect(
          generatedContent,
          contains('static const ApiSettings apiSettings'),
        );

        // Check values
        expect(generatedContent, contains('\'Welcome to our app!\''));
        expect(generatedContent, contains('defaultValue: false'));
        expect(generatedContent, contains('3.0'));
        expect(generatedContent, contains('\'#007AFF\''));
        expect(generatedContent, contains('300.0'));

        // Check descriptions
        expect(generatedContent, contains('/// Welcome message for users'));
        expect(generatedContent, contains('/// User interface settings'));
        expect(generatedContent, contains('/// Primary UI color'));

        // Check Firebase methods are included
        expect(generatedContent, contains('Future<T> getRemoteValue() async'));
        expect(generatedContent, contains('T getValue()'));
        expect(generatedContent, contains('Stream<T> observeValue()'));
      });

      test('handles minimal template successfully', () async {
        final minimalTemplate = {
          'parameters': {
            'simple_param': {
              'valueType': 'STRING',
              'defaultValue': {'value': 'simple_value'},
            },
          },
        };

        final templateFile = File('${tempDir.path}/minimal.json');
        await templateFile.writeAsString(json.encode(minimalTemplate));

        await generator.generateFromPaths(
          templatePath: templateFile.path,
          outputPath: '${tempDir.path}/output',
        );

        final outputFile = File(
          '${tempDir.path}/output/remote_config_params.gen.dart',
        );
        expect(outputFile.existsSync(), isTrue);

        final content = await outputFile.readAsString();
        expect(
          content,
          contains('static const RemoteConfigParam<String> simpleParam'),
        );
        expect(content, contains('\'simple_value\''));
      });

      test('handles empty template successfully', () async {
        final emptyTemplate = {
          'parameters': <String, dynamic>{},
          'parameterGroups': <String, dynamic>{},
        };

        final templateFile = File('${tempDir.path}/empty.json');
        await templateFile.writeAsString(json.encode(emptyTemplate));

        await generator.generateFromPaths(
          templatePath: templateFile.path,
          outputPath: '${tempDir.path}/output',
        );

        final outputFile = File(
          '${tempDir.path}/output/remote_config_params.gen.dart',
        );
        expect(outputFile.existsSync(), isTrue);

        final content = await outputFile.readAsString();
        expect(content, contains('class RemoteConfigParams'));
        expect(content, contains('const RemoteConfigParams._();'));
      });

      test('propagates template parsing errors', () async {
        final invalidTemplate = File('${tempDir.path}/invalid.json');
        await invalidTemplate.writeAsString('{ invalid json }');

        await expectLater(
          () => generator.generateFromPaths(
            templatePath: invalidTemplate.path,
            outputPath: '${tempDir.path}/output',
          ),
          throwsA(isA<TemplateException>()),
        );
      });

      test('propagates file writing errors', () async {
        final template = {
          'parameters': {
            'test': {
              'valueType': 'STRING',
              'defaultValue': {'value': 'test'},
            },
          },
        };

        final templateFile = File('${tempDir.path}/template.json');
        await templateFile.writeAsString(json.encode(template));

        // Try to write to an invalid path
        await expectLater(
          () => generator.generateFromPaths(
            templatePath: templateFile.path,
            outputPath: '/invalid/path/that/cannot/be/created',
          ),
          throwsA(isA<CodeGenerationException>()),
        );
      });
    });

    group('generate (with config file)', () {
      test('generates using configuration file', () async {
        // Create template
        final template = {
          'test_param': 'from config',
          'parameters': {
            'test_param': {
              'valueType': 'STRING',
              'defaultValue': {'useInAppDefault': true},
            },
          },
        };

        final templateFile = File('${tempDir.path}/config_template.json');
        await templateFile.writeAsString(json.encode(template));

        // Create config file
        final configFile = File('${tempDir.path}/test_config.yaml');
        await configFile.writeAsString('''
input: ${templateFile.path}
output: ${tempDir.path}/config_output
''');

        // Generate using config
        await generator.generate(configFile.path);

        // Verify output
        final outputFile = File(
          '${tempDir.path}/config_output/remote_config_params.gen.dart',
        );
        expect(outputFile.existsSync(), isTrue);

        final content = await outputFile.readAsString();
        expect(
          content,
          contains('static const RemoteConfigParam<String> testParam'),
        );
        expect(content, contains('\'from config\''));
      });

      test('propagates configuration errors', () async {
        await expectLater(
          () => generator.generate('nonexistent_config.yaml'),
          throwsA(isA<ConfigurationException>()),
        );
      });
    });

    group('edge cases', () {
      test('handles complex parameter names correctly', () async {
        final template = {
          'parameters': {
            'snake_case_param': {
              'valueType': 'STRING',
              'defaultValue': {'value': 'snake_value'},
            },
            'UPPER_CASE_PARAM': {
              'valueType': 'STRING',
              'defaultValue': {'value': 'upper_value'},
            },
            'mixed_Case_Param': {
              'valueType': 'STRING',
              'defaultValue': {'value': 'mixed_value'},
            },
          },
        };

        final templateFile = File('${tempDir.path}/complex_names.json');
        await templateFile.writeAsString(json.encode(template));

        await generator.generateFromPaths(
          templatePath: templateFile.path,
          outputPath: '${tempDir.path}/output',
        );

        final outputFile = File(
          '${tempDir.path}/output/remote_config_params.gen.dart',
        );
        final content = await outputFile.readAsString();

        expect(
          content,
          contains('static const RemoteConfigParam<String> snakeCaseParam'),
        );
        expect(
          content,
          contains('static const RemoteConfigParam<String> upperCaseParam'),
        );
        expect(
          content,
          contains('static const RemoteConfigParam<String> mixedCaseParam'),
        );
      });

      test('handles all value types correctly', () async {
        final template = {
          'string_param': 'test string',
          'bool_param': true,
          'number_param': 42.5,
          'json_param': '{"key": "value", "number": 123}',
          'parameters': {
            'string_param': {
              'valueType': 'STRING',
              'defaultValue': {'useInAppDefault': true},
            },
            'bool_param': {
              'valueType': 'BOOLEAN',
              'defaultValue': {'useInAppDefault': true},
            },
            'number_param': {
              'valueType': 'NUMBER',
              'defaultValue': {'useInAppDefault': true},
            },
            'json_param': {
              'valueType': 'JSON',
              'defaultValue': {'useInAppDefault': true},
            },
          },
        };

        final templateFile = File('${tempDir.path}/all_types.json');
        await templateFile.writeAsString(json.encode(template));

        await generator.generateFromPaths(
          templatePath: templateFile.path,
          outputPath: '${tempDir.path}/output',
        );

        final outputFile = File(
          '${tempDir.path}/output/remote_config_params.gen.dart',
        );
        final content = await outputFile.readAsString();

        expect(content, contains('RemoteConfigParam<String> stringParam'));
        expect(content, contains('RemoteConfigParam<bool> boolParam'));
        expect(content, contains('RemoteConfigParam<double> numberParam'));
        expect(content, contains('RemoteConfigParam<String> jsonParam'));

        expect(content, contains('\'test string\''));
        expect(content, contains('true'));
        expect(content, contains('42.5'));
        expect(
          content,
          contains('r\'\'\'{"key": "value", "number": 123}\'\'\''),
        );
      });
    });
  });
}
