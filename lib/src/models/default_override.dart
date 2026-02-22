/// Internal model for a default value override from remote_config_gen.yaml.
///
/// Only boolean overrides are supported in the current version;
/// the structure is extensible for future types.
class DefaultOverride {
  const DefaultOverride({
    required this.groupName,
    required this.paramKey,
    required this.value,
  });

  /// Group name from the template's [parameterGroups], or null for top-level params.
  final String? groupName;

  /// Parameter key (same as in the Firebase template).
  final String paramKey;

  /// Override value. Only [bool] is supported in this version.
  final bool value;

  /// Dot-separated path for display (e.g. "feature_flags.new_onboarding" or "max_retry_count").
  String get path =>
      groupName != null ? '$groupName.$paramKey' : paramKey;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DefaultOverride &&
        other.groupName == groupName &&
        other.paramKey == paramKey &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(groupName, paramKey, value);
}
