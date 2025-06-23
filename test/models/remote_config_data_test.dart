import 'package:test/test.dart';
import 'package:remote_config_gen/src/models/remote_config_data.dart';

void main() {
  group('RemoteConfigParameter', () {
    test('creates parameter with all fields', () {
      const param = RemoteConfigParameter(
        key: 'test_key',
        valueType: 'STRING',
        defaultValue: 'test_value',
        description: 'Test description',
      );

      expect(param.key, equals('test_key'));
      expect(param.valueType, equals('STRING'));
      expect(param.defaultValue, equals('test_value'));
      expect(param.description, equals('Test description'));
    });

    test('creates parameter without description', () {
      const param = RemoteConfigParameter(
        key: 'test_key',
        valueType: 'BOOLEAN',
        defaultValue: true,
      );

      expect(param.key, equals('test_key'));
      expect(param.valueType, equals('BOOLEAN'));
      expect(param.defaultValue, equals(true));
      expect(param.description, isNull);
    });

    group('dartType getter', () {
      test('returns correct type for BOOLEAN', () {
        const param = RemoteConfigParameter(
          key: 'test',
          valueType: 'BOOLEAN',
          defaultValue: true,
        );
        expect(param.dartType, equals('bool'));
      });

      test('returns correct type for NUMBER', () {
        const param = RemoteConfigParameter(
          key: 'test',
          valueType: 'NUMBER',
          defaultValue: 42.0,
        );
        expect(param.dartType, equals('double'));
      });

      test('returns correct type for JSON', () {
        const param = RemoteConfigParameter(
          key: 'test',
          valueType: 'JSON',
          defaultValue: '{}',
        );
        expect(param.dartType, equals('String'));
      });

      test('returns correct type for STRING', () {
        const param = RemoteConfigParameter(
          key: 'test',
          valueType: 'STRING',
          defaultValue: 'value',
        );
        expect(param.dartType, equals('String'));
      });

      test('returns correct type for unknown type', () {
        const param = RemoteConfigParameter(
          key: 'test',
          valueType: 'UNKNOWN',
          defaultValue: 'value',
        );
        expect(param.dartType, equals('String'));
      });

      test('handles case insensitive types', () {
        const param = RemoteConfigParameter(
          key: 'test',
          valueType: 'boolean',
          defaultValue: true,
        );
        expect(param.dartType, equals('bool'));
      });
    });

    test('equality works correctly', () {
      const param1 = RemoteConfigParameter(
        key: 'test',
        valueType: 'STRING',
        defaultValue: 'value',
        description: 'desc',
      );
      const param2 = RemoteConfigParameter(
        key: 'test',
        valueType: 'STRING',
        defaultValue: 'value',
        description: 'desc',
      );
      const param3 = RemoteConfigParameter(
        key: 'different',
        valueType: 'STRING',
        defaultValue: 'value',
        description: 'desc',
      );

      expect(param1, equals(param2));
      expect(param1, isNot(equals(param3)));
      expect(param1.hashCode, equals(param2.hashCode));
    });

    test('toString works correctly', () {
      const param = RemoteConfigParameter(
        key: 'test_key',
        valueType: 'STRING',
        defaultValue: 'test_value',
        description: 'Test description',
      );

      final result = param.toString();
      expect(result, contains('test_key'));
      expect(result, contains('STRING'));
      expect(result, contains('test_value'));
      expect(result, contains('Test description'));
    });
  });

  group('RemoteConfigParameterGroup', () {
    test('creates group with parameters', () {
      final params = {
        'param1': const RemoteConfigParameter(
          key: 'param1',
          valueType: 'STRING',
          defaultValue: 'value1',
        ),
        'param2': const RemoteConfigParameter(
          key: 'param2',
          valueType: 'BOOLEAN',
          defaultValue: true,
        ),
      };

      final group = RemoteConfigParameterGroup(
        key: 'test_group',
        parameters: params,
        description: 'Test group',
      );

      expect(group.key, equals('test_group'));
      expect(group.parameters, equals(params));
      expect(group.description, equals('Test group'));
    });

    test('creates group without description', () {
      final params = <String, RemoteConfigParameter>{};
      final group = RemoteConfigParameterGroup(
        key: 'test_group',
        parameters: params,
      );

      expect(group.key, equals('test_group'));
      expect(group.parameters, equals(params));
      expect(group.description, isNull);
    });

    test('equality works correctly', () {
      final params = {
        'param1': const RemoteConfigParameter(
          key: 'param1',
          valueType: 'STRING',
          defaultValue: 'value1',
        ),
      };

      final group1 = RemoteConfigParameterGroup(
        key: 'test',
        parameters: params,
        description: 'desc',
      );
      final group2 = RemoteConfigParameterGroup(
        key: 'test',
        parameters: params,
        description: 'desc',
      );
      final group3 = RemoteConfigParameterGroup(
        key: 'different',
        parameters: params,
        description: 'desc',
      );

      expect(group1, equals(group2));
      expect(group1, isNot(equals(group3)));
      expect(group1.hashCode, equals(group2.hashCode));
    });
  });

  group('RemoteConfigData', () {
    test('creates data with all components', () {
      final parameters = {
        'param1': const RemoteConfigParameter(
          key: 'param1',
          valueType: 'STRING',
          defaultValue: 'value1',
        ),
      };

      final groups = {
        'group1': RemoteConfigParameterGroup(
          key: 'group1',
          parameters: parameters,
        ),
      };

      final rawData = {'test': 'data'};

      final data = RemoteConfigData(
        parameters: parameters,
        parameterGroups: groups,
        rawData: rawData,
      );

      expect(data.parameters, equals(parameters));
      expect(data.parameterGroups, equals(groups));
      expect(data.rawData, equals(rawData));
    });

    test('equality works correctly', () {
      final parameters = {
        'param1': const RemoteConfigParameter(
          key: 'param1',
          valueType: 'STRING',
          defaultValue: 'value1',
        ),
      };
      final groups = <String, RemoteConfigParameterGroup>{};
      final rawData = {'test': 'data'};

      final data1 = RemoteConfigData(
        parameters: parameters,
        parameterGroups: groups,
        rawData: rawData,
      );
      final data2 = RemoteConfigData(
        parameters: parameters,
        parameterGroups: groups,
        rawData: rawData,
      );

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
    });
  });
}
