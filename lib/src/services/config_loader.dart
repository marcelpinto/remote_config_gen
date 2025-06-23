import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

import '../exceptions/remote_config_exception.dart';
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

      return GenerationConfig(inputPath: inputPath, outputPath: outputPath);
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
}
