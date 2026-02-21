/// Defines how to convert a raw JSON map into [T] and back.
///
/// Implement this for any Remote Config parameter with valueType JSON.
abstract interface class RemoteConfigConverter<T> {
  const RemoteConfigConverter();
  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T value);
}
