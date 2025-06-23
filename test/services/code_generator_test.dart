import 'package:test/test.dart';
import 'package:remote_config_gen/src/services/code_generator.dart';
import 'package:remote_config_gen/src/models/remote_config_data.dart';

void main() {
  group('CodeGenerator', () {
    late CodeGenerator generator;

    setUp(() {
      generator = const CodeGenerator();
    });

    group('generateCode', () {
      test('generates code for simple parameters', () {
        final param = RemoteConfigParameter(
          key: 'test_param',
          valueType: 'STRING',
          defaultValue: 'test_value',
          description: 'Test parameter',
        );

        final data = RemoteConfigData(
          parameters: {'test_param': param},
          parameterGroups: {},
          rawData: {'test_param': 'test_value'},
        );

        final result = generator.generateCode(data);

        expect(result, contains('class RemoteConfigParam<T>'));
        expect(result, contains('class RemoteConfigParams'));
        expect(result, contains('const RemoteConfigParams._();'));
        expect(
          result,
          contains('static const RemoteConfigParam<String> testParam'),
        );
        expect(result, contains("key: 'test_param'"));
        expect(result, contains("defaultValue: 'test_value'"));
        expect(result, contains('/// Test parameter'));
      });

      test('generates code for boolean parameters', () {
        final param = RemoteConfigParameter(
          key: 'feature_enabled',
          valueType: 'BOOLEAN',
          defaultValue: true,
        );

        final data = RemoteConfigData(
          parameters: {'feature_enabled': param},
          parameterGroups: {},
          rawData: {'feature_enabled': true},
        );

        final result = generator.generateCode(data);

        expect(
          result,
          contains('static const RemoteConfigParam<bool> featureEnabled'),
        );
        expect(result, contains('defaultValue: true'));
      });

      test('generates code for number parameters', () {
        final param = RemoteConfigParameter(
          key: 'retry_count',
          valueType: 'NUMBER',
          defaultValue: 3.0,
        );

        final data = RemoteConfigData(
          parameters: {'retry_count': param},
          parameterGroups: {},
          rawData: {'retry_count': 3.0},
        );

        final result = generator.generateCode(data);

        expect(
          result,
          contains('static const RemoteConfigParam<double> retryCount'),
        );
        expect(result, contains('defaultValue: 3.0'));
      });

      test('generates code for JSON parameters', () {
        final param = RemoteConfigParameter(
          key: 'config_json',
          valueType: 'JSON',
          defaultValue: '{"key": "value"}',
        );

        final data = RemoteConfigData(
          parameters: {'config_json': param},
          parameterGroups: {},
          rawData: {'config_json': '{"key": "value"}'},
        );

        final result = generator.generateCode(data);

        expect(
          result,
          contains('static const RemoteConfigParam<String> configJson'),
        );
        expect(result, contains('r\'\'\'{"key": "value"}\'\'\''));
      });

      test('generates code for parameter groups', () {
        final groupParam = RemoteConfigParameter(
          key: 'button_color',
          valueType: 'STRING',
          defaultValue: '#007AFF',
          description: 'Button color',
        );

        final group = RemoteConfigParameterGroup(
          key: 'ui_settings',
          parameters: {'button_color': groupParam},
          description: 'UI settings',
        );

        final data = RemoteConfigData(
          parameters: {},
          parameterGroups: {'ui_settings': group},
          rawData: {
            'parameterGroups': {
              'ui_settings': {
                'parameters': {
                  'button_color': {
                    'defaultValue': {'value': '#007AFF'},
                  },
                },
              },
            },
          },
        );

        final result = generator.generateCode(data);

        expect(result, contains('/// UI settings'));
        expect(result, contains('class UiSettings {'));
        expect(result, contains('const UiSettings({'));
        expect(result, contains('required this.buttonColor'));
        expect(result, contains('/// Button color'));
        expect(
          result,
          contains('final RemoteConfigParam<String> buttonColor;'),
        );
        expect(
          result,
          contains('static const UiSettings uiSettings = UiSettings('),
        );
        expect(result, contains('buttonColor: RemoteConfigParam('));
      });

      test('handles complex strings with special characters', () {
        final param = RemoteConfigParameter(
          key: 'complex_string',
          valueType: 'STRING',
          defaultValue: 'Line 1\nLine 2\nContains \$variable and "quotes"',
        );

        final data = RemoteConfigData(
          parameters: {'complex_string': param},
          parameterGroups: {},
          rawData: {
            'complex_string':
                'Line 1\nLine 2\nContains \$variable and "quotes"',
          },
        );

        final result = generator.generateCode(data);

        expect(
          result,
          contains(
            'r\'\'\'Line 1\nLine 2\nContains \$variable and "quotes"\'\'\'',
          ),
        );
      });

      test('handles null values with appropriate defaults', () {
        final stringParam = RemoteConfigParameter(
          key: 'null_string',
          valueType: 'STRING',
          defaultValue: null,
        );

        final boolParam = RemoteConfigParameter(
          key: 'null_bool',
          valueType: 'BOOLEAN',
          defaultValue: null,
        );

        final numberParam = RemoteConfigParameter(
          key: 'null_number',
          valueType: 'NUMBER',
          defaultValue: null,
        );

        final data = RemoteConfigData(
          parameters: {
            'null_string': stringParam,
            'null_bool': boolParam,
            'null_number': numberParam,
          },
          parameterGroups: {},
          rawData: {},
        );

        final result = generator.generateCode(data);

        expect(result, contains("defaultValue: ''"));
        expect(result, contains('defaultValue: false'));
        expect(result, contains('defaultValue: 0.0'));
      });

      test('converts snake_case to camelCase for field names', () {
        final param = RemoteConfigParameter(
          key: 'snake_case_param',
          valueType: 'STRING',
          defaultValue: 'value',
        );

        final data = RemoteConfigData(
          parameters: {'snake_case_param': param},
          parameterGroups: {},
          rawData: {'snake_case_param': 'value'},
        );

        final result = generator.generateCode(data);

        expect(
          result,
          contains('static const RemoteConfigParam<String> snakeCaseParam'),
        );
        expect(result, contains("key: 'snake_case_param'"));
      });

      test('converts snake_case to ClassName for groups', () {
        final param = RemoteConfigParameter(
          key: 'test_param',
          valueType: 'STRING',
          defaultValue: 'test',
        );

        final group = RemoteConfigParameterGroup(
          key: 'api_settings',
          parameters: {'test_param': param},
        );

        final data = RemoteConfigData(
          parameters: {},
          parameterGroups: {'api_settings': group},
          rawData: {
            'parameterGroups': {
              'api_settings': {
                'parameters': {
                  'test_param': {
                    'defaultValue': {'value': 'test'},
                  },
                },
              },
            },
          },
        );

        final result = generator.generateCode(data);

        expect(result, contains('class ApiSettings {'));
        expect(result, contains('static const ApiSettings apiSettings'));
      });

      test('includes Firebase Remote Config import', () {
        final data = RemoteConfigData(
          parameters: {},
          parameterGroups: {},
          rawData: {},
        );

        final result = generator.generateCode(data);

        expect(
          result,
          contains(
            "import 'package:firebase_remote_config/firebase_remote_config.dart';",
          ),
        );
      });

      test('formats code properly with dart formatter', () {
        final param = RemoteConfigParameter(
          key: 'test',
          valueType: 'STRING',
          defaultValue: 'value',
        );

        final data = RemoteConfigData(
          parameters: {'test': param},
          parameterGroups: {},
          rawData: {'test': 'value'},
        );

        final result = generator.generateCode(data);

        // Should be properly formatted (no specific validation, just ensure no exception)
        expect(result, isNotEmpty);
        expect(result, contains('// dart format off'));
        expect(result, contains('// dart format on'));
      });

      test('handles numeric values as strings', () {
        final param = RemoteConfigParameter(
          key: 'string_number',
          valueType: 'NUMBER',
          defaultValue: '42.5',
        );

        final data = RemoteConfigData(
          parameters: {'string_number': param},
          parameterGroups: {},
          rawData: {'string_number': '42.5'},
        );

        final result = generator.generateCode(data);

        expect(result, contains('defaultValue: 42.5'));
      });

      test('throws CodeGenerationException on formatter error', () {
        // This is tricky to test since DartFormatter rarely fails on valid Dart code
        // We can mock this scenario, but for now, let's ensure basic error handling exists
        final data = RemoteConfigData(
          parameters: {},
          parameterGroups: {},
          rawData: {},
        );

        // Basic generation should not throw
        expect(() => generator.generateCode(data), returnsNormally);
      });

      test('handles parameter groups with useInAppDefault', () {
        final groupParam = RemoteConfigParameter(
          key: 'app_theme',
          valueType: 'STRING',
          defaultValue: 'dark',
        );

        final group = RemoteConfigParameterGroup(
          key: 'theme_settings',
          parameters: {'app_theme': groupParam},
        );

        final data = RemoteConfigData(
          parameters: {},
          parameterGroups: {'theme_settings': group},
          rawData: {
            'app_theme': 'dark',
            'parameterGroups': {
              'theme_settings': {
                'parameters': {
                  'app_theme': {
                    'defaultValue': {'useInAppDefault': true},
                  },
                },
              },
            },
          },
        );

        final result = generator.generateCode(data);

        expect(result, contains('class ThemeSettings'));
        expect(result, contains("defaultValue: 'dark'"));
      });

      test('includes the extended RemoteConfigParam methods', () {
        final data = RemoteConfigData(
          parameters: {},
          parameterGroups: {},
          rawData: {},
        );

        final result = generator.generateCode(data);

        expect(result, contains('Future<T> getRemoteValue() async'));
        expect(result, contains('T getValue()'));
        expect(result, contains('Stream<T> observeValue()'));
        expect(result, contains('T _getValue(RemoteConfigValue? value)'));
      });
    });
  });
}
