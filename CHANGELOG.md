## 0.1.0

* **JSON Converters**: Added support for typed JSON parameters via `RemoteConfigConverter<T>` and `RemoteConfigJsonParam<T>`.
  * Define a converter class and map it to a JSON parameter in `remote_config_gen.yaml`.
  * The generator emits `RemoteConfigJsonParam<T>` with automatic JSON-to-type conversion.
  * JSON parameters without a converter remain `RemoteConfigParam<String>` (backward compatible).
  * Warnings are printed for JSON params that have no converter configured.
* Added `RemoteConfigConverter<T>` abstract interface class.
* Added `RemoteConfigJsonParam<T>` runtime class with `getValue()`, `observeValue()`, and lazy `defaultValue` conversion.
* Added `ConverterConfig` model and `converters` section to YAML configuration.
* Updated example project to demonstrate JSON converter usage with `ThemeConfig`.

## 0.0.2

* Updated README.

## 0.0.1

* Initial release.
