# Remote Config Generator

A tool to generate Dart classes from a Firebase Remote Config templates for
type safe and static typing. No more hardcoded values!

## Usage

1. Add the dev_dependency

    ```yaml
    dev_dependencies:
        remote_config_gen: 0.0.2
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

## Limitations

The same limitations as Firebase Remote config applies. Meaning, you can only use the following types:

* String
* Boolean
* Numbers (int/double)
* JSON: a JSON string formatted value. It will be returned as `String`, you need to do the conversion yourself.
