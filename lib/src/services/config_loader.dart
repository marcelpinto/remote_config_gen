import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

import '../exceptions/remote_config_exception.dart';
import '../models/converter_config.dart';
import '../models/default_override.dart';
import '../models/generation_config.dart';

/// Service responsible for loading configuration from YAML files.
class ConfigLoader {
  const ConfigLoader();

  /// Loads generation configuration from the specified file.
  ///
  /// Defaults to 'remote_config_gen.yaml' if no path is provided.
  GenerationConfig loadConfig([String configPath = 'remote_config_gen.yaml']) {
    try {
      final configFile = File(configPath);

      if (!configFile.existsSync()) {
        throw ConfigurationException(
          'Configuration file not found: $configPath',
        );
      }

      final configContent = configFile.readAsStringSync();
      final yamlMap = yaml.loadYaml(configContent);

      if (yamlMap is! Map) {
        throw ConfigurationException(
          'Invalid configuration file format. Expected a YAML map.',
        );
      }

      final config = Map<String, dynamic>.from(yamlMap);

      final inputPath = config['input'] as String?;
      if (inputPath == null || inputPath.isEmpty) {
        throw ConfigurationException(
          'Input path is not set in the configuration file',
        );
      }

      final outputPath = config['output'] as String?;
      if (outputPath == null || outputPath.isEmpty) {
        throw ConfigurationException(
          'Output path is not set in the configuration file',
        );
      }

      final converters = _parseConverters(config);
      final (overrides, parseWarnings) = _parseDefaults(config['defaults']);

      return GenerationConfig(
        inputPath: inputPath,
        outputPath: outputPath,
        converters: converters,
        defaultOverrides: overrides,
        defaultParseWarnings: parseWarnings,
      );
    } on yaml.YamlException catch (e) {
      throw ConfigurationException(
        'Failed to parse YAML configuration: ${e.message}',
      );
    } on FileSystemException catch (e) {
      throw ConfigurationException(
        'Failed to read configuration file: ${e.message}',
      );
    }
  }

  /// Parses the optional `converters` section from the config YAML.
  Map<String, ConverterConfig> _parseConverters(Map<String, dynamic> config) {
    final raw = config['converters'];
    if (raw == null) return const {};

    if (raw is! Map) {
      throw ConfigurationException(
        'Invalid converters section: expected a YAML map.',
      );
    }

    final result = <String, ConverterConfig>{};

    for (final entry in raw.entries) {
      final paramKey = entry.key as String;
      final value = entry.value;

      if (value is! Map) {
        throw ConfigurationException(
          'Converter entry for "$paramKey" must be a map with type, converter, and import fields.',
        );
      }

      final converterMap = Map<String, dynamic>.from(value);

      final type = converterMap['type'] as String?;
      if (type == null || type.isEmpty) {
        throw ConfigurationException(
          'Converter for "$paramKey" is missing the "type" field.',
        );
      }

      final converter = converterMap['converter'] as String?;
      if (converter == null || converter.isEmpty) {
        throw ConfigurationException(
          'Converter for "$paramKey" is missing the "converter" field.',
        );
      }

      final import = converterMap['import'] as String?;
      if (import == null || import.isEmpty) {
        throw ConfigurationException(
          'Converter for "$paramKey" is missing the "import" field.',
        );
      }

      result[paramKey] = ConverterConfig(
        paramKey: paramKey,
        type: type,
        converter: converter,
        import: import,
      );
    }

    return result;
  }

  /// Parses the optional `defaults` section from the config YAML.
  ///
  /// Returns (overrides, parseWarnings). Only boolean leaf values are
  /// included; non-boolean leaves produce a warning.
  (List<DefaultOverride>, List<String>) _parseDefaults(dynamic raw) {
    final overrides = <DefaultOverride>[];
    final warnings = <String>[];

    if (raw == null) return (overrides, warnings);
    if (raw is! Map) {
      warnings.add('defaults section must be a YAML map, ignored.');
      return (overrides, warnings);
    }

    void walk(Map<dynamic, dynamic> map, String? groupName) {
      for (final entry in map.entries) {
        final key = entry.key is String ? entry.key as String : entry.key.toString();
        final value = entry.value;

        if (value is Map) {
          walk(Map<dynamic, dynamic>.from(value), key);
        } else {
          if (value is bool) {
            overrides.add(DefaultOverride(
              groupName: groupName,
              paramKey: key,
              value: value,
            ));
          } else {
            final path = groupName != null ? '$groupName.$key' : key;
            warnings.add(
              "Default override for '$path' ignored: only boolean overrides "
              'are supported in this version.',
            );
          }
        }
      }
    }

    walk(Map<dynamic, dynamic>.from(raw), null);
    return (overrides, warnings);
  }
}
