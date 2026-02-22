# Remote Config Generator

A tool to generate Dart classes from a Firebase Remote Config templates for
type safe and static typing. No more hardcoded values!

## Usage

1. Add the dev_dependency

    ```yaml
    dev_dependencies:
        remote_config_gen: 0.1.0
    ```

2. Download/Fetch the `remoteconfig.template.json` for your project

    ```bash
    firebase remoteconfig:get -o remoteconfig.template.json
    ```

3. Create a `remote_config_gen.yaml` file and define the configuration:

    ```yaml
    input: remoteconfig.template.json
    output: lib/generated
    ```

4. Run the generator

    ```bash
    dart run remote_config_gen
    ```

5. Use the generated parameters:

    ```dart
    import 'package:remote_config_gen/remote_config_gen.dart';

    // It will return either the remote value or the default defined in the template
    int value = RemoteConfigParams.maxRetryCount.getValue();

    // It also accepts remote config groups
    bool isDark = RemoteConfigParams.uiSettings.darkMode.getValue();
    ```

6. (Optional) Change values in the template and update Firebase Remote Config

    ```bash
    firebase deploy --only remoteconfig
    ```

    > Note: you can also manually do the changes in the Firebase dashboard and sync the changes again

## Observing value changes

The generated `RemoteConfigParam` includes a method that returns a `Stream`, allowing you to observe Remote Config changes while the app is running.

```dart
RemoteConfigParams.uiSettings.darkMode.observeValue().listen((bool isDarkMode) {
    // Change the UI based on the new value
});
```

## JSON Converters

For parameters with `valueType: JSON`, you can get fully typed access using converters. Instead of working with raw JSON strings, the generator will emit `RemoteConfigJsonParam<T>` that automatically converts values through your converter.

### 1. Define a model and converter

```dart
// lib/models/theme_config.dart
class ThemeConfig {
  const ThemeConfig({required this.primaryColor, required this.darkMode});
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
}
```

```dart
// lib/models/theme_config_converter.dart
import 'package:my_app/generated/remote_config_params.gen.dart';
import 'theme_config.dart';

class ThemeConfigConverter extends RemoteConfigConverter<ThemeConfig> {
  const ThemeConfigConverter();

  @override
  ThemeConfig fromJson(Map<String, dynamic> json) => ThemeConfig.fromJson(json);

  @override
  Map<String, dynamic> toJson(ThemeConfig value) => value.toJson();
}
```

### 2. Add the converter to `remote_config_gen.yaml`

```yaml
input: remoteconfig.template.json
output: lib/generated
converters:
  theme_config:
    type: ThemeConfig
    converter: ThemeConfigConverter
    import: package:my_app/models/theme_config_converter.dart
```

The key under `converters` must match a parameter key in your Remote Config template that has `valueType: JSON`.

### 3. Run the generator

```bash
dart run remote_config_gen
```

### 4. Use the typed result

```dart
// Typed access — no manual JSON parsing needed
ThemeConfig theme = RemoteConfigParams.themeConfig.getValue();
print(theme.primaryColor); // '#FF0000'
print(theme.darkMode);     // false

// Observe typed changes
RemoteConfigParams.themeConfig.observeValue().listen((ThemeConfig theme) {
  // React to config changes with full type safety
});
```

JSON parameters **without** a converter entry will continue to be generated as `RemoteConfigParam<String>` (the existing behavior), so this feature is fully backward compatible. The generator will print a warning for JSON params without a converter to prompt you to add one.

## Limitations

The same limitations as Firebase Remote config applies. Meaning, you can only use the following types:

* String
* Boolean
* Numbers (int/double)
* JSON: either as a typed value via converters (see above) or as a raw `String` that you parse yourself.
