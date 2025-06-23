/// Configuration model for code generation.

/// Configuration for remote config generation.
class GenerationConfig {
  const GenerationConfig({required this.inputPath, required this.outputPath});

  final String inputPath;
  final String outputPath;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenerationConfig &&
        other.inputPath == inputPath &&
        other.outputPath == outputPath;
  }

  @override
  int get hashCode => Object.hash(inputPath, outputPath);

  @override
  String toString() {
    return 'GenerationConfig('
        'inputPath: $inputPath, '
        'outputPath: $outputPath)';
  }
}
