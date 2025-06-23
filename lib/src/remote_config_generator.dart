import 'services/config_loader.dart';
import 'services/template_parser.dart';
import 'services/code_generator.dart';
import 'services/file_writer.dart';

/// Main service that orchestrates the remote config generation process.
class RemoteConfigGenerator {
  const RemoteConfigGenerator({
    ConfigLoader? configLoader,
    TemplateParser? templateParser,
    CodeGenerator? codeGenerator,
    FileWriter? fileWriter,
  }) : _configLoader = configLoader ?? const ConfigLoader(),
       _templateParser = templateParser ?? const TemplateParser(),
       _codeGenerator = codeGenerator ?? const CodeGenerator(),
       _fileWriter = fileWriter ?? const FileWriter();

  final ConfigLoader _configLoader;
  final TemplateParser _templateParser;
  final CodeGenerator _codeGenerator;
  final FileWriter _fileWriter;

  /// Generates remote config code from the default configuration file.
  Future<void> generate([String? configPath]) async {
    final config = _configLoader.loadConfig(
      configPath ?? 'remote_config_gen.yaml',
    );
    await generateFromPaths(
      templatePath: config.inputPath,
      outputPath: config.outputPath,
    );
  }

  /// Generates remote config code from specific template and output paths.
  Future<void> generateFromPaths({
    required String templatePath,
    required String outputPath,
  }) async {
    // Parse the template
    final remoteConfigData = await _templateParser.parseTemplate(templatePath);

    // Generate the code
    final generatedCode = _codeGenerator.generateCode(remoteConfigData);

    // Write the code to file
    await _fileWriter.writeGeneratedCode(
      outputPath: outputPath,
      generatedCode: generatedCode,
    );
  }
}
