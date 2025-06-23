/// Data models for remote config representation.

/// Represents a remote config parameter.
class RemoteConfigParameter {
  const RemoteConfigParameter({
    required this.key,
    required this.valueType,
    required this.defaultValue,
    this.description,
  });

  final String key;
  final String valueType;
  final dynamic defaultValue;
  final String? description;

  /// Gets the Dart type for this parameter.
  String get dartType {
    switch (valueType.toUpperCase()) {
      case 'BOOLEAN':
        return 'bool';
      case 'NUMBER':
        return 'double';
      case 'JSON':
        return 'String';
      case 'STRING':
      default:
        return 'String';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RemoteConfigParameter &&
        other.key == key &&
        other.valueType == valueType &&
        other.defaultValue == defaultValue &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(key, valueType, defaultValue, description);

  @override
  String toString() {
    return 'RemoteConfigParameter('
        'key: $key, '
        'valueType: $valueType, '
        'defaultValue: $defaultValue, '
        'description: $description)';
  }
}

/// Represents a group of remote config parameters.
class RemoteConfigParameterGroup {
  const RemoteConfigParameterGroup({
    required this.key,
    required this.parameters,
    this.description,
  });

  final String key;
  final Map<String, RemoteConfigParameter> parameters;
  final String? description;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RemoteConfigParameterGroup &&
        other.key == key &&
        _mapEquals(other.parameters, parameters) &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(key, parameters, description);

  @override
  String toString() {
    return 'RemoteConfigParameterGroup('
        'key: $key, '
        'parameters: $parameters, '
        'description: $description)';
  }

  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Represents the entire remote config data.
class RemoteConfigData {
  const RemoteConfigData({
    required this.parameters,
    required this.parameterGroups,
    required this.rawData,
  });

  final Map<String, RemoteConfigParameter> parameters;
  final Map<String, RemoteConfigParameterGroup> parameterGroups;
  final Map<String, dynamic> rawData;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RemoteConfigData &&
        _mapEquals(other.parameters, parameters) &&
        _mapEquals(other.parameterGroups, parameterGroups) &&
        _mapEquals(other.rawData, rawData);
  }

  @override
  int get hashCode => Object.hash(parameters, parameterGroups, rawData);

  @override
  String toString() {
    return 'RemoteConfigData('
        'parameters: $parameters, '
        'parameterGroups: $parameterGroups)';
  }

  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
