/// Utility functions for string manipulation.
class StringUtils {
  const StringUtils._();

  /// Converts a snake_case string to camelCase.
  static String toCamelCase(String input) {
    if (!input.contains('_')) {
      return input;
    }

    final parts = input.split('_');
    final first = parts.first.toLowerCase();
    final rest = parts.skip(1).map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    });

    return first + rest.join();
  }

  /// Converts a snake_case string to ClassName.
  static String toClassName(String input) {
    final words = input.split('_');
    return words
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join();
  }
}
