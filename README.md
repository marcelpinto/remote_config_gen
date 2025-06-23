# Remote Config Generator

A tool to generate Dart classes from Firebase Remote Config templates for
type safe and static typing. No more hardcoded values!

## Usage

1. Add the dev_dependency

    ```yaml
    dev_dependencies:
    remote_config_gen: 0.0.1
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
