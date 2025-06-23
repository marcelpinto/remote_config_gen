import 'dart:io';

import '../exceptions/remote_config_exception.dart';

/// Service responsible for writing generated code to files.
class FileWriter {
  const FileWriter();

  /// Writes the generated code to the specified output directory.
  Future<void> writeGeneratedCode({
    required String outputPath,
    required String generatedCode,
    String fileName = 'remote_config_params.gen.dart',
  }) async {
    try {
      // Create output directory if it doesn't exist
      final outputDir = Directory(outputPath);
      if (!outputDir.existsSync()) {
        await outputDir.create(recursive: true);
      }

      // Write the generated code to file
      final outputFile = File('$outputPath/$fileName');
      await outputFile.writeAsString(generatedCode);
    } on FileSystemException catch (e) {
      throw CodeGenerationException(
        'Failed to write generated code to file: ${e.message}',
      );
    }
  }
}
