import '../generated/remote_config_params.gen.dart';
import 'theme_config.dart';

/// Converter that bridges [ThemeConfig] with Remote Config JSON values.
class ThemeConfigConverter implements RemoteConfigConverter<ThemeConfig> {
  const ThemeConfigConverter();

  @override
  ThemeConfig fromJson(Map<String, dynamic> json) => ThemeConfig.fromJson(json);
}
