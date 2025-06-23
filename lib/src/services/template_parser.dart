import 'dart:convert';
import 'dart:io';

import '../exceptions/remote_config_exception.dart';
import '../models/remote_config_data.dart';

/// Service responsible for parsing remote config templates.
class TemplateParser {
  const TemplateParser();

  /// Parses a remote config template from the specified file path.
  Future<RemoteConfigData> parseTemplate(String templatePath) async {
    try {
      final templateFile = File(templatePath);

      if (!templateFile.existsSync()) {
        throw TemplateException('Template file does not exist: $templatePath');
      }

      final content = await templateFile.readAsString();
      final Map<String, dynamic> remoteConfig;

      try {
        remoteConfig = json.decode(content) as Map<String, dynamic>;
      } on FormatException catch (e) {
        throw TemplateException(
          'Invalid JSON format in template file: ${e.message}',
        );
      }

      final parameters = _parseParameters(remoteConfig);
      final parameterGroups = _parseParameterGroups(remoteConfig);

      return RemoteConfigData(
        parameters: parameters,
        parameterGroups: parameterGroups,
        rawData: remoteConfig,
      );
    } on FileSystemException catch (e) {
      throw TemplateException('Failed to read template file: ${e.message}');
    }
  }

  /// Parses parameters from the remote config data.
  Map<String, RemoteConfigParameter> _parseParameters(
    Map<String, dynamic> remoteConfig,
  ) {
    final params = remoteConfig['parameters'] as Map<String, dynamic>? ?? {};
    final result = <String, RemoteConfigParameter>{};

    for (final entry in params.entries) {
      final key = entry.key;
      final param = entry.value as Map<String, dynamic>?;

      if (param == null) {
        throw ParameterValidationException(
          'Parameter $key has invalid structure',
        );
      }

      final valueType = param['valueType'] as String?;
      if (valueType == null) {
        throw ParameterValidationException(
          'Parameter $key is missing valueType',
        );
      }

      final defaultValue = _extractDefaultValue(key, param, remoteConfig);
      final description = _extractDescription(param);

      result[key] = RemoteConfigParameter(
        key: key,
        valueType: valueType,
        defaultValue: defaultValue,
        description: description,
      );
    }

    return result;
  }

  /// Parses parameter groups from the remote config data.
  Map<String, RemoteConfigParameterGroup> _parseParameterGroups(
    Map<String, dynamic> remoteConfig,
  ) {
    final groups =
        remoteConfig['parameterGroups'] as Map<String, dynamic>? ?? {};
    final result = <String, RemoteConfigParameterGroup>{};

    for (final entry in groups.entries) {
      final key = entry.key;
      final group = entry.value as Map<String, dynamic>?;

      if (group == null) {
        throw ParameterValidationException(
          'Parameter group $key has invalid structure',
        );
      }

      final groupParams = _parseParameters({
        'parameters': group['parameters'] ?? {},
      });

      final description = group['description'] as String?;

      result[key] = RemoteConfigParameterGroup(
        key: key,
        parameters: groupParams,
        description: description,
      );
    }

    return result;
  }

  /// Extracts the default value for a parameter.
  dynamic _extractDefaultValue(
    String key,
    Map<String, dynamic> param,
    Map<String, dynamic> remoteConfig,
  ) {
    final defaultValue = param['defaultValue'];

    if (defaultValue == null) {
      throw ParameterValidationException(
        'Parameter $key is missing defaultValue',
      );
    }

    if (defaultValue is Map<String, dynamic>) {
      final useInAppDefault = defaultValue['useInAppDefault'] as bool?;

      if (useInAppDefault == true) {
        final value = remoteConfig[key];
        if (value == null) {
          throw ParameterValidationException(
            'Remote config $key is not set but useInAppDefault is true',
          );
        }
        return value;
      } else {
        final value = defaultValue['value'];
        if (value == null) {
          throw ParameterValidationException(
            'Remote config default value for $key is not set',
          );
        }
        return value;
      }
    }

    return defaultValue;
  }

  /// Extracts description from parameter data.
  String? _extractDescription(Map<String, dynamic> param) {
    final description = param['description'];

    if (description is String) {
      return description;
    }

    if (description is Map<String, dynamic>) {
      return description['description'] as String?;
    }

    return null;
  }
}
