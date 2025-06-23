/// Custom exceptions for remote config generation.

/// Base exception for remote config generation errors.
sealed class RemoteConfigException implements Exception {
  const RemoteConfigException(this.message);

  final String message;

  @override
  String toString() => 'RemoteConfigException: $message';
}

/// Thrown when configuration is invalid.
class ConfigurationException extends RemoteConfigException {
  const ConfigurationException(super.message);

  @override
  String toString() => 'ConfigurationException: $message';
}

/// Thrown when template file operations fail.
class TemplateException extends RemoteConfigException {
  const TemplateException(super.message);

  @override
  String toString() => 'TemplateException: $message';
}

/// Thrown when code generation fails.
class CodeGenerationException extends RemoteConfigException {
  const CodeGenerationException(super.message);

  @override
  String toString() => 'CodeGenerationException: $message';
}

/// Thrown when parameter validation fails.
class ParameterValidationException extends RemoteConfigException {
  const ParameterValidationException(super.message);

  @override
  String toString() => 'ParameterValidationException: $message';
}
