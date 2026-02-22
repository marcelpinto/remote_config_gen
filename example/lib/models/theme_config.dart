/// Example model for a JSON-based remote config parameter.
class ThemeConfig {
  const ThemeConfig({
    required this.primaryColor,
    required this.darkMode,
  });

  final String primaryColor;
  final bool darkMode;

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      primaryColor: json['primaryColor'] as String? ?? '#000000',
      darkMode: json['darkMode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'primaryColor': primaryColor,
        'darkMode': darkMode,
      };

  @override
  String toString() =>
      'ThemeConfig(primaryColor: $primaryColor, darkMode: $darkMode)';
}
