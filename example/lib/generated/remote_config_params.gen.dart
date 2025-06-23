// dart format off
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:firebase_remote_config/firebase_remote_config.dart';

/// A class that represents a remote config parameter with its
/// key and default value
class RemoteConfigParam<T> {
  /// The key used to fetch this parameter from Firebase Remote Config
  final String key;

  /// The default value to use if the remote value is not available
  final T defaultValue;

  /// Creates a new RemoteConfigParam with the given key and default value
  const RemoteConfigParam({required this.key, required this.defaultValue});

  /// Returns the current value of the remote config parameter or fetches and
  /// activates it if it's not available.
  Future<T> getRemoteValue() async {
    RemoteConfigValue? remoteConfigValue;
    remoteConfigValue = FirebaseRemoteConfig.instance.getValue(key);
    if (remoteConfigValue.source == ValueSource.valueRemote) {
      return _getValue(remoteConfigValue);
    }

    await FirebaseRemoteConfig.instance.fetchAndActivate();
    remoteConfigValue = FirebaseRemoteConfig.instance.getValue(key);
    return _getValue(remoteConfigValue);
  }

  /// Returns the current value of the remote config parameter. It might be
  /// the remote or the default value.
  T getValue() {
    final value = FirebaseRemoteConfig.instance.getValue(key);
    if (value.source == ValueSource.valueRemote) {
      return _getValue(value);
    }
    return defaultValue;
  }

  /// Returns a stream that emits the current value of the remote config
  /// parameter when it changes.
  Stream<T> observeValue() {
    return FirebaseRemoteConfig.instance.onConfigUpdated.map((event) {
      final value = FirebaseRemoteConfig.instance.getValue(key);
      if (value.source == ValueSource.valueRemote) {
        return _getValue(value);
      }
      return defaultValue;
    });
  }

  T _getValue(RemoteConfigValue? value) {
    if (value == null) {
      throw Exception("Remote config value not found");
    }
    if (T == bool) {
      return value.asBool() as T;
    }
    if (T == String) {
      return value.asString() as T;
    }
    if (T == int) {
      return value.asInt() as T;
    }
    if (T == double) {
      return value.asDouble() as T;
    }
    throw Exception("Unsupported type");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RemoteConfigParam<T> &&
        other.key == key &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode => key.hashCode ^ defaultValue.hashCode;

  @override
  String toString() =>
      'RemoteConfigParam(key: $key, defaultValue: $defaultValue)';
}

/// User interface related settings
class UiSettings {
  const UiSettings({
    required this.primaryColor,
    required this.darkMode,
    required this.buttonColor,
    required this.animationDuration,
  });

  /// Primary color
  final RemoteConfigParam<String> primaryColor;

  /// Dark mode
  final RemoteConfigParam<bool> darkMode;

  /// Primary button color
  final RemoteConfigParam<String> buttonColor;

  /// Animation duration in milliseconds
  final RemoteConfigParam<double> animationDuration;
}

/// API related configuration
class ApiSettings {
  const ApiSettings({
    required this.baseUrl,
    required this.enableLogging,
  });

  /// Base URL for API requests
  final RemoteConfigParam<String> baseUrl;

  /// Enable API request logging
  final RemoteConfigParam<bool> enableLogging;
}

class RemoteConfigParams {
  const RemoteConfigParams._();

  /// Message shown to users when they first open the app
  static const RemoteConfigParam<String> welcomeMessage = RemoteConfigParam(
    key: 'welcome_message',
    defaultValue: 'Welcome to our amazing app!',
  );

  /// Whether the new feature is enabled for users
  static const RemoteConfigParam<bool> featureEnabled = RemoteConfigParam(
    key: 'feature_enabled',
    defaultValue: true,
  );

  /// Maximum number of retry attempts for network requests
  static const RemoteConfigParam<double> maxRetryCount = RemoteConfigParam(
    key: 'max_retry_count',
    defaultValue: 3.0,
  );

  /// API request timeout in seconds
  static const RemoteConfigParam<double> apiTimeout = RemoteConfigParam(
    key: 'api_timeout',
    defaultValue: 30.0,
  );

  /// Languages configuration as JSON
  static const RemoteConfigParam<String> languagesConfig = RemoteConfigParam(
    key: 'languages_config',
    defaultValue: r'''{"en": "English", "fr": "French"}''',
  );

  /// User interface related settings
  static const UiSettings uiSettings = UiSettings(
    primaryColor: RemoteConfigParam(
      key: 'primary_color',
      defaultValue: '#a0a0a0',
    ),
    darkMode: RemoteConfigParam(
      key: 'dark_mode',
      defaultValue: false,
    ),
    buttonColor: RemoteConfigParam(
      key: 'button_color',
      defaultValue: '#007AFF',
    ),
    animationDuration: RemoteConfigParam(
      key: 'animation_duration',
      defaultValue: 300.0,
    ),
  );

  /// API related configuration
  static const ApiSettings apiSettings = ApiSettings(
    baseUrl: RemoteConfigParam(
      key: 'base_url',
      defaultValue: 'https://api.example.com',
    ),
    enableLogging: RemoteConfigParam(
      key: 'enable_logging',
      defaultValue: false,
    ),
  );
}
// dart format on
