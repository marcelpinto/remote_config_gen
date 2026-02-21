import '../generated/remote_config_params.gen.dart';
import 'theme_config.dart';

/// Converter that bridges [ThemeConfig] with Remote Config JSON values.
class ThemeConfigConverter extends RemoteConfigConverter<ThemeConfig> {
  const ThemeConfigConverter();

  @override
  ThemeConfig fromJson(Map<String, dynamic> json) =>
      ThemeConfig.fromJson(json);

  @override
  Map<String, dynamic> toJson(ThemeConfig value) => value.toJson();
}
