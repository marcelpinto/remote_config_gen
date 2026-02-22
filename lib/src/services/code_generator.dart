import 'dart:convert';
import 'dart:io' as io;

import 'package:dart_style/dart_style.dart';

import '../exceptions/remote_config_exception.dart';
import '../models/converter_config.dart';
import '../models/remote_config_data.dart';
import '../utils/string_utils.dart';

/// Service responsible for generating Dart code from remote config data.
class CodeGenerator {
  const CodeGenerator();

  /// Warnings collected during the last [generateCode] call.
  ///
  /// Use this after calling [generateCode] to inspect non-fatal issues
  /// such as JSON params without a configured converter.
  final List<String> warnings = const [];

  /// Generates formatted Dart code from remote config data.
  ///
  /// If [converters] is provided, JSON params with matching keys will emit
  /// `RemoteConfigJsonParam<T>` instead of `RemoteConfigParam<String>`.
  String generateCode(
    RemoteConfigData data, {
    Map<String, ConverterConfig> converters = const {},
  }) {
    try {
      final mutableWarnings = <String>[];
      final buffer = StringBuffer();

      _generateHeader(buffer);
      _generateImports(buffer, converters);
      _generateRemoteConfigParamClass(buffer);
      _generateJsonParamClassIfNeeded(buffer, converters);
      _generateParameterGroupClasses(buffer, data.parameterGroups);
      _generateMainClass(buffer, data, converters, mutableWarnings);

      for (final w in mutableWarnings) {
        io.stderr.writeln('[WARNING] $w');
      }

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

  /// Generates import statements, including user-specified converter imports.
  void _generateImports(
    StringBuffer buffer,
    Map<String, ConverterConfig> converters,
  ) {
    buffer.writeln(
      "import 'package:firebase_remote_config/firebase_remote_config.dart';",
    );

    if (converters.isNotEmpty) {
      buffer.writeln("import 'dart:convert';");
    }

    final uniqueImports = <String>{};
    for (final c in converters.values) {
      uniqueImports.add(c.import);
    }
    for (final imp in uniqueImports) {
      buffer.writeln("import '$imp';");
    }

    buffer.writeln();
  }

  /// Generates the RemoteConfigParam class.
  void _generateRemoteConfigParamClass(StringBuffer buffer) {
    buffer.writeln("""
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

  /// Generates the RemoteConfigJsonParam class when converters are in use.
  void _generateJsonParamClassIfNeeded(
    StringBuffer buffer,
    Map<String, ConverterConfig> converters,
  ) {
    if (converters.isEmpty) return;

    buffer.writeln("""
/// Defines how to convert a raw JSON map into [T] and back.
abstract interface class RemoteConfigConverter<T> {
  const RemoteConfigConverter();
  T fromJson(Map<String, dynamic> json);
}

/// A remote config parameter that holds JSON data and converts it to [T]
/// using the provided [RemoteConfigConverter].
class RemoteConfigJsonParam<T> {
  const RemoteConfigJsonParam({
    required this.key,
    required this.defaultValueJson,
    required this.converter,
  });

  final String key;
  final Map<String, dynamic> defaultValueJson;
  final RemoteConfigConverter<T> converter;

  T get defaultValue => converter.fromJson(defaultValueJson);

  T getValue([FirebaseRemoteConfig? instance]) {
    final rc = instance ?? FirebaseRemoteConfig.instance;
    final raw = rc.getString(key);
    if (raw.isEmpty) return defaultValue;
    try {
      return converter.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return defaultValue;
    }
  }

  Stream<T> observeValue([FirebaseRemoteConfig? instance]) {
    final rc = instance ?? FirebaseRemoteConfig.instance;
    return rc.onConfigUpdated.map((_) => getValue(rc));
  }
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
  void _generateMainClass(
    StringBuffer buffer,
    RemoteConfigData data,
    Map<String, ConverterConfig> converters,
    List<String> warnings,
  ) {
    buffer.writeln('class RemoteConfigParams {');
    buffer.writeln('  const RemoteConfigParams._();');
    buffer.writeln();

    // Generate main parameters
    for (final param in data.parameters.values) {
      final converterConfig = converters[param.key];
      final isJson = param.valueType.toUpperCase() == 'JSON';

      if (isJson && converterConfig == null) {
        warnings.add(
          'Parameter "${param.key}" has valueType JSON but no converter is '
          'configured. It will be generated as RemoteConfigParam<String>. '
          'Add a converter entry in remote_config_gen.yaml to get typed access.',
        );
      }

      if (isJson && converterConfig != null) {
        _generateConverterParam(buffer, param, converterConfig);
      } else {
        _generateStandardParam(buffer, param);
      }
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

  /// Generates a standard RemoteConfigParam field.
  void _generateStandardParam(
    StringBuffer buffer,
    RemoteConfigParameter param,
  ) {
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

  /// Generates a RemoteConfigJsonParam field with a converter.
  void _generateConverterParam(
    StringBuffer buffer,
    RemoteConfigParameter param,
    ConverterConfig converterConfig,
  ) {
    if (param.description != null) {
      buffer.writeln('  /// ${param.description}');
    }

    final fieldName = StringUtils.toCamelCase(param.key);
    final converterName = converterConfig.converter;

    buffer.writeln(
      '  static const ${fieldName}Converter = ${converterName}();',
    );
    buffer.writeln('  static const $fieldName = RemoteConfigJsonParam(');
    buffer.writeln('    key: \'${param.key}\',');
    buffer.writeln(
      '    defaultValueJson: ${_formatJsonDefaultValue(param.defaultValue)},',
    );
    buffer.writeln('    converter: ${fieldName}Converter,');
    buffer.writeln('  );');
    buffer.writeln();
  }

  /// Formats the default value for a JSON param as a Dart map literal.
  String _formatJsonDefaultValue(dynamic value) {
    if (value == null) return '<String, dynamic>{}';

    if (value is String) {
      try {
        final parsed = json.decode(value);
        if (parsed is Map) {
          return _mapToLiteral(
            Map<String, dynamic>.from(parsed),
            isConst: false,
          );
        }
      } catch (_) {
        // fall through
      }
      return '<String, dynamic>{}';
    }

    if (value is Map) {
      return _mapToLiteral(Map<String, dynamic>.from(value), isConst: false);
    }

    return '<String, dynamic>{}';
  }

  /// Converts a map to a const Dart map literal string.
  String _mapToLiteral(Map<String, dynamic> map, {bool isConst = true}) {
    if (map.isEmpty)
      return isConst ? 'const <String, dynamic>{}' : '<String, dynamic>{}';

    final entries = map.entries
        .map((e) {
          final key = "'${_escapeString(e.key)}'";
          final val = _valueToDartLiteral(e.value);
          return '$key: $val';
        })
        .join(', ');

    return isConst
        ? 'const <String, dynamic>{$entries}'
        : '<String, dynamic>{$entries}';
  }

  /// Converts a JSON value to a Dart literal representation.
  String _valueToDartLiteral(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return value.toString();
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is String) return "'${_escapeString(value)}'";
    if (value is List) {
      final items = value.map(_valueToDartLiteral).join(', ');
      return 'const <dynamic>[$items]';
    }
    if (value is Map) {
      return _mapToLiteral(Map<String, dynamic>.from(value));
    }
    return "'${value.toString()}'";
  }

  /// Escapes special characters in a string for Dart code.
  String _escapeString(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll(r'$', r'\$');
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
          try {
            json.decode(value);
            return _formatStringValue(value);
          } catch (_) {
            return _formatStringValue(value);
          }
        }
        return _formatStringValue(value.toString());
      default:
        return _formatStringValue(value.toString());
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
  String _formatStringValue(String value) {
    if (value.contains('\n') ||
        value.contains("'") ||
        value.contains(r'$') ||
        value.contains('"')) {
      return "r'''$value'''";
    }
    return "'$value'";
  }
}
