import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:remote_config_gen/src/services/template_parser.dart';
import 'package:remote_config_gen/src/exceptions/remote_config_exception.dart';

void main() {
  group('TemplateParser', () {
    late Directory tempDir;
    late TemplateParser parser;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('template_parser_test_');
      parser = const TemplateParser();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('parseTemplate', () {
      test('parses valid template successfully', () async {
        final template = {
          'welcome_message': 'Hello World!',
          'parameters': {
            'welcome_message': {
              'valueType': 'STRING',
              'defaultValue': {'useInAppDefault': true},
            },
            'feature_enabled': {
              'valueType': 'BOOLEAN',
              'defaultValue': {'value': true},
            },
          },
          'parameterGroups': {
            'ui_settings': {
              'description': 'UI related settings',
              'parameters': {
                'button_color': {
                  'valueType': 'STRING',
                  'defaultValue': {'value': '#007AFF'},
                },
              },
            },
          },
        };

        final templateFile = File('${tempDir.path}/template.json');
        await templateFile.writeAsString(json.encode(template));

        final result = await parser.parseTemplate(templateFile.path);

        expect(result.parameters, hasLength(2));
        expect(
          result.parameters['welcome_message']?.key,
          equals('welcome_message'),
        );
        expect(
          result.parameters['welcome_message']?.valueType,
          equals('STRING'),
        );
        expect(
          result.parameters['welcome_message']?.defaultValue,
          equals('Hello World!'),
        );

        expect(
          result.parameters['feature_enabled']?.key,
          equals('feature_enabled'),
        );
        expect(
          result.parameters['feature_enabled']?.valueType,
          equals('BOOLEAN'),
        );
        expect(
          result.parameters['feature_enabled']?.defaultValue,
          equals(true),
        );

        expect(result.parameterGroups, hasLength(1));
        expect(
          result.parameterGroups['ui_settings']?.key,
          equals('ui_settings'),
        );
        expect(
          result.parameterGroups['ui_settings']?.description,
          equals('UI related settings'),
        );
        expect(result.parameterGroups['ui_settings']?.parameters, hasLength(1));
      });

      test('throws TemplateException when file does not exist', () async {
        await expectLater(
          () => parser.parseTemplate('nonexistent.json'),
          throwsA(
            isA<TemplateException>().having(
              (e) => e.message,
              'message',
              contains('does not exist'),
            ),
          ),
        );
      });

      test('throws TemplateException for invalid JSON', () async {
        final templateFile = File('${tempDir.path}/invalid.json');
        await templateFile.writeAsString('{ invalid json }');

        await expectLater(
          () => parser.parseTemplate(templateFile.path),
          throwsA(
            isA<TemplateException>().having(
              (e) => e.message,
              'message',
              contains('Invalid JSON format'),
            ),
          ),
        );
      });

      test('handles empty parameters section', () async {
        final template = {
          'parameters': <String, dynamic>{},
          'parameterGroups': <String, dynamic>{},
        };

        final templateFile = File('${tempDir.path}/empty.json');
        await templateFile.writeAsString(json.encode(template));

        final result = await parser.parseTemplate(templateFile.path);

        expect(result.parameters, isEmpty);
        expect(result.parameterGroups, isEmpty);
      });

      test(
        'throws ParameterValidationException for missing valueType',
        () async {
          final template = {
            'parameters': {
              'invalid_param': {
                'defaultValue': {'value': 'test'},
              },
            },
          };

          final templateFile = File('${tempDir.path}/missing_type.json');
          await templateFile.writeAsString(json.encode(template));

          await expectLater(
            () => parser.parseTemplate(templateFile.path),
            throwsA(
              isA<ParameterValidationException>().having(
                (e) => e.message,
                'message',
                contains('missing valueType'),
              ),
            ),
          );
        },
      );

      test(
        'throws ParameterValidationException for missing defaultValue',
        () async {
          final template = {
            'parameters': {
              'invalid_param': {'valueType': 'STRING'},
            },
          };

          final templateFile = File('${tempDir.path}/missing_default.json');
          await templateFile.writeAsString(json.encode(template));

          await expectLater(
            () => parser.parseTemplate(templateFile.path),
            throwsA(
              isA<ParameterValidationException>().having(
                (e) => e.message,
                'message',
                contains('missing defaultValue'),
              ),
            ),
          );
        },
      );

      test(
        'throws ParameterValidationException when useInAppDefault is true but value not found',
        () async {
          final template = {
            'parameters': {
              'missing_value': {
                'valueType': 'STRING',
                'defaultValue': {'useInAppDefault': true},
              },
            },
          };

          final templateFile = File('${tempDir.path}/missing_app_default.json');
          await templateFile.writeAsString(json.encode(template));

          await expectLater(
            () => parser.parseTemplate(templateFile.path),
            throwsA(
              isA<ParameterValidationException>().having(
                (e) => e.message,
                'message',
                contains('is not set but useInAppDefault is true'),
              ),
            ),
          );
        },
      );

      test(
        'throws ParameterValidationException when defaultValue.value is missing',
        () async {
          final template = {
            'parameters': {
              'missing_default_value': {
                'valueType': 'STRING',
                'defaultValue': {'useInAppDefault': false},
              },
            },
          };

          final templateFile = File(
            '${tempDir.path}/missing_default_value.json',
          );
          await templateFile.writeAsString(json.encode(template));

          await expectLater(
            () => parser.parseTemplate(templateFile.path),
            throwsA(
              isA<ParameterValidationException>().having(
                (e) => e.message,
                'message',
                contains('default value for missing_default_value is not set'),
              ),
            ),
          );
        },
      );

      test('handles parameter with description as string', () async {
        final template = {
          'parameters': {
            'described_param': {
              'valueType': 'STRING',
              'defaultValue': {'value': 'test'},
              'description': 'Simple description',
            },
          },
        };

        final templateFile = File('${tempDir.path}/described.json');
        await templateFile.writeAsString(json.encode(template));

        final result = await parser.parseTemplate(templateFile.path);

        expect(
          result.parameters['described_param']?.description,
          equals('Simple description'),
        );
      });

      test('handles parameter with description as object', () async {
        final template = {
          'parameters': {
            'described_param': {
              'valueType': 'STRING',
              'defaultValue': {'value': 'test'},
              'description': {'description': 'Object description'},
            },
          },
        };

        final templateFile = File('${tempDir.path}/described_object.json');
        await templateFile.writeAsString(json.encode(template));

        final result = await parser.parseTemplate(templateFile.path);

        expect(
          result.parameters['described_param']?.description,
          equals('Object description'),
        );
      });

      test('handles parameter groups with invalid structure', () async {
        final template = {
          'parameterGroups': {'invalid_group': null},
        };

        final templateFile = File('${tempDir.path}/invalid_group.json');
        await templateFile.writeAsString(json.encode(template));

        await expectLater(
          () => parser.parseTemplate(templateFile.path),
          throwsA(
            isA<ParameterValidationException>().having(
              (e) => e.message,
              'message',
              contains('has invalid structure'),
            ),
          ),
        );
      });

      test('handles filesystem errors gracefully', () async {
        final templateFile = File('${tempDir.path}/test.json');
        await templateFile.writeAsString('{}');

        // Delete the temp directory to cause a filesystem error
        tempDir.deleteSync(recursive: true);

        await expectLater(
          () => parser.parseTemplate(templateFile.path),
          throwsA(
            isA<TemplateException>().having(
              (e) => e.message,
              'message',
              contains('does not exist'),
            ),
          ),
        );
      });

      test('handles direct defaultValue (not object)', () async {
        final template = {
          'parameters': {
            'simple_param': {
              'valueType': 'STRING',
              'defaultValue': 'direct_value',
            },
          },
        };

        final templateFile = File('${tempDir.path}/direct_default.json');
        await templateFile.writeAsString(json.encode(template));

        final result = await parser.parseTemplate(templateFile.path);

        expect(
          result.parameters['simple_param']?.defaultValue,
          equals('direct_value'),
        );
      });
    });
  });
}
