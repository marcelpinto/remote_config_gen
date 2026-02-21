import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'remote_config_converter.dart';

/// A remote config parameter that holds JSON data and converts it to [T]
/// using the provided [RemoteConfigConverter].
///
/// The [defaultValueJson] is stored as a raw JSON map and lazily converted
/// to [T] via [converter] the first time [defaultValue] is accessed.
class RemoteConfigJsonParam<T> {
  const RemoteConfigJsonParam({
    required this.key,
    required this.defaultValueJson,
    required this.converter,
  });

  final String key;
  final Map<String, dynamic> defaultValueJson;
  final RemoteConfigConverter<T> converter;

  /// Returns the default value by converting [defaultValueJson] with [converter].
  T get defaultValue => converter.fromJson(defaultValueJson);

  /// Returns the current value of the remote config parameter.
  ///
  /// Falls back to [defaultValue] when the remote string is empty or
  /// the JSON cannot be decoded.
  T getValue([FirebaseRemoteConfig? instance]) {
    final rc = instance ?? FirebaseRemoteConfig.instance;
    final raw = rc.getString(key);
    if (raw.isEmpty) return defaultValue;
    try {
      return converter.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return defaultValue;
    }
  }

  /// Returns a stream that emits the converted value whenever Remote Config
  /// is updated.
  Stream<T> observeValue([FirebaseRemoteConfig? instance]) {
    final rc = instance ?? FirebaseRemoteConfig.instance;
    return rc.onConfigUpdated.map((_) => getValue(rc));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RemoteConfigJsonParam<T> &&
        other.key == key &&
        _mapEquals(other.defaultValueJson, defaultValueJson);
  }

  @override
  int get hashCode => key.hashCode ^ defaultValueJson.hashCode;

  @override
  String toString() =>
      'RemoteConfigJsonParam(key: $key, defaultValueJson: $defaultValueJson)';

  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
