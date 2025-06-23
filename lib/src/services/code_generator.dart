import 'dart:convert';

import 'package:dart_style/dart_style.dart';

import '../exceptions/remote_config_exception.dart';
import '../models/remote_config_data.dart';
import '../utils/string_utils.dart';

/// Service responsible for generating Dart code from remote config data.
class CodeGenerator {
  const CodeGenerator();

  /// Generates formatted Dart code from remote config data.
  String generateCode(RemoteConfigData data) {
    try {
      final buffer = StringBuffer();

      _generateHeader(buffer);
      _generateRemoteConfigParamClass(buffer);
      _generateParameterGroupClasses(buffer, data.parameterGroups);
      _generateMainClass(buffer, data);

      final formatter = DartFormatter(
        languageVersion: DartFormatter.latestShortStyleLanguageVersion,
      );

      return formatter.format(buffer.toString());
    } catch (e) {
      throw CodeGenerationException('Failed to generate code: $e');
    }
  }

  /// Generates the file header.
  void _generateHeader(StringBuffer buffer) {
    buffer.writeln('// dart format off');
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln();
  }

  /// Generates the RemoteConfigParam class.
  void _generateRemoteConfigParamClass(StringBuffer buffer) {
    buffer.writeln("""
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// A class that represents a remote config parameter with its
/// key and default value
class RemoteConfigParam<T> {
  /// The key used to fetch this parameter from Firebase Remote Config
  final String key;

  /// The default value to use if the remote value is not available
  final T defaultValue;

  /// Creates a new RemoteConfigParam with the given key and default value
  const RemoteConfigParam({required this.key, required this.defaultValue});

  /// Returns the current value of the remote config parameter or fetches and
  /// activates it if it's not available.
  Future<T> getRemoteValue() async {
    RemoteConfigValue? remoteConfigValue;
    remoteConfigValue = FirebaseRemoteConfig.instance.getValue(key);
    if (remoteConfigValue.source == ValueSource.valueRemote) {
      return _getValue(remoteConfigValue);
    }
    
    await FirebaseRemoteConfig.instance.fetchAndActivate();
    remoteConfigValue = FirebaseRemoteConfig.instance.getValue(key);
    return _getValue(remoteConfigValue);
  }

  /// Returns the current value of the remote config parameter. It might be
  /// the remote or the default value.
  T getValue() {
    final value = FirebaseRemoteConfig.instance.getValue(key);
    if (value.source == ValueSource.valueRemote) {
      return _getValue(value);
    }
    return defaultValue;
  }

  /// Returns a stream that emits the current value of the remote config
  /// parameter when it changes.
  Stream<T> observeValue() {
    return FirebaseRemoteConfig.instance.onConfigUpdated.map((event) {
      final value = FirebaseRemoteConfig.instance.getValue(key);
      if (value.source == ValueSource.valueRemote) {
        return _getValue(value);
      }
      return defaultValue;
    });
  }

  T _getValue(RemoteConfigValue? value) {
    if (value == null) {
      throw Exception("Remote config value not found");
    }
    if (T == bool) {
      return value.asBool() as T;
    }
    if (T == String) {
      return value.asString() as T;
    }
    if (T == int) {
      return value.asInt() as T;
    }
    if (T == double) {
      return value.asDouble() as T;
    }
    throw Exception("Unsupported type");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RemoteConfigParam<T> &&
        other.key == key &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode => key.hashCode ^ defaultValue.hashCode;

  @override
  String toString() =>
      'RemoteConfigParam(key: \$key, defaultValue: \$defaultValue)';
}
  """);
    buffer.writeln();
  }

  /// Generates parameter group classes.
  void _generateParameterGroupClasses(
    StringBuffer buffer,
    Map<String, RemoteConfigParameterGroup> groups,
  ) {
    for (final group in groups.values) {
      final className = StringUtils.toClassName(group.key);

      if (group.description != null) {
        buffer.writeln('/// ${group.description}');
      }
      buffer.writeln('class $className {');

      // Constructor
      final paramNames =
          group.parameters.keys.map(StringUtils.toCamelCase).toList();
      buffer.writeln('  const $className({');
      for (final paramName in paramNames) {
        buffer.writeln('    required this.$paramName,');
      }
      buffer.writeln('  });');
      buffer.writeln();

      // Fields
      for (final param in group.parameters.values) {
        if (param.description != null) {
          buffer.writeln('  /// ${param.description}');
        }
        buffer.writeln(
          '  final RemoteConfigParam<${param.dartType}> ${StringUtils.toCamelCase(param.key)};',
        );
        buffer.writeln();
      }

      buffer.writeln('}');
      buffer.writeln();
    }
  }

  /// Generates the main RemoteConfigParams class.
  void _generateMainClass(StringBuffer buffer, RemoteConfigData data) {
    buffer.writeln('class RemoteConfigParams {');
    buffer.writeln('  const RemoteConfigParams._();');
    buffer.writeln();

    // Generate main parameters
    for (final param in data.parameters.values) {
      if (param.description != null) {
        buffer.writeln('  /// ${param.description}');
      }
      buffer.writeln(
        '  static const RemoteConfigParam<${param.dartType}> ${StringUtils.toCamelCase(param.key)} = RemoteConfigParam(',
      );
      buffer.writeln('    key: \'${param.key}\',');
      buffer.writeln(
        '    defaultValue: ${_formatValue(param.defaultValue, param.dartType)},',
      );
      buffer.writeln('  );');
      buffer.writeln();
    }

    // Generate parameter groups
    for (final group in data.parameterGroups.values) {
      final className = StringUtils.toClassName(group.key);

      if (group.description != null) {
        buffer.writeln('  /// ${group.description}');
      }
      buffer.writeln(
        '  static const $className ${StringUtils.toCamelCase(group.key)} = $className(',
      );

      for (final param in group.parameters.values) {
        final value = _extractGroupParameterValue(
          group.key,
          param,
          data.rawData,
        );

        buffer.writeln(
          '    ${StringUtils.toCamelCase(param.key)}: RemoteConfigParam(',
        );
        buffer.writeln('      key: \'${param.key}\',');
        buffer.writeln(
          '      defaultValue: ${_formatValue(value, param.dartType)},',
        );
        buffer.writeln('    ),');
      }
      buffer.writeln('  );');
      buffer.writeln();
    }

    buffer.writeln('}');
    buffer.writeln('// dart format on');
  }

  /// Extracts the value for a parameter within a group.
  dynamic _extractGroupParameterValue(
    String groupKey,
    RemoteConfigParameter param,
    Map<String, dynamic> rawData,
  ) {
    final groupData =
        rawData['parameterGroups']?[groupKey] as Map<String, dynamic>?;
    final paramData =
        groupData?['parameters']?[param.key] as Map<String, dynamic>?;
    final defaultValue = paramData?['defaultValue'];

    if (defaultValue is Map<String, dynamic>) {
      final useInAppDefault = defaultValue['useInAppDefault'] as bool?;
      if (useInAppDefault == true) {
        return rawData[param.key];
      } else {
        return defaultValue['value'];
      }
    }

    return defaultValue;
  }

  /// Formats a value for Dart code generation.
  String _formatValue(dynamic value, String type) {
    if (value == null) {
      return _getDefaultValueForType(type);
    }

    switch (type) {
      case 'bool':
        return value.toString().toLowerCase();
      case 'double':
        final numValue =
            value is num ? value : double.tryParse(value.toString()) ?? 0.0;
        return numValue.toString();
      case 'String':
        if (type == 'String' && value is String) {
          // Check if it's JSON by trying to parse it
          try {
            json.decode(value);
            return _formatString(value);
          } catch (_) {
            return _formatString(value);
          }
        }
        return _formatString(value.toString());
      default:
        return _formatString(value.toString());
    }
  }

  /// Returns the default value for a given type.
  String _getDefaultValueForType(String type) {
    switch (type) {
      case 'bool':
        return 'false';
      case 'double':
        return '0.0';
      case 'String':
      default:
        return "''";
    }
  }

  /// Formats a string value for Dart code.
  String _formatString(String value) {
    if (value.contains('\n') ||
        value.contains("'") ||
        value.contains(r'$') ||
        value.contains('"')) {
      return "r'''$value'''";
    }
    return "'$value'";
  }
}
