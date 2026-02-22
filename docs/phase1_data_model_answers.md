# Phase 1 — Data Model Answers

Answers to the two design questions, derived from the existing generator source.

---

## 1. How does the generator represent a param group internally?

**Short answer:** Groups are keyed by the **exact template key** (the `parameterGroups` key from the Firebase JSON). The yaml `defaults` nesting must use those same keys.

**Details:**

- **Template JSON:** `parameterGroups` is a map: key = group name (e.g. `"feature_flags"`, `"ui_settings"`), value = `{ "parameters": { "param_key": { ... } } }`.
- **Template parser** (`lib/src/services/template_parser.dart`):
  - `_parseParameterGroups` iterates `remoteConfig['parameterGroups']` and uses the **literal key from the JSON** as `RemoteConfigParameterGroup.key` (see line 104: `result[key] = RemoteConfigParameterGroup(key: key, ...)`).
  - So internal representation uses **template keys**, e.g. `group.key == "ui_settings"` (not the generated class name `UiSettings`).
- **Code generator** (`lib/src/services/code_generator.dart`):
  - Uses `group.key` for raw lookup: `rawData['parameterGroups']?[groupKey]` (line 424).
  - Dart names are derived from that key: `StringUtils.toClassName(group.key)` → class name, `StringUtils.toCamelCase(group.key)` → static field name.

**Implication for defaults:** The yaml `defaults` structure should mirror the template:

- Top-level params: keys in `defaults` that are **not** in `parameterGroups` are top-level parameter keys (e.g. `max_retry_count`).
- Group params: keys in `defaults` that **are** in `parameterGroups` are groups; their value is a map of param keys to default overrides (e.g. `feature_flags.new_onboarding` → group `feature_flags`, param `new_onboarding`).

So the plan’s design is correct: **yaml structure matches template structure**; we use template group names and param keys everywhere. No ambiguity.

---

## 2. How does the generator resolve `defaultValue` from the template?

**Short answer:** Two places — top-level params use `param.defaultValue`; group params use `_extractGroupParameterValue(...)`. Override logic should sit in front of both.

**Top-level parameters**

- **Where:** `code_generator.dart`, `_generateStandardParam` (lines 324–337).
- **How:** Uses `param.defaultValue` directly:
  ```dart
  buffer.writeln(
    '    defaultValue: ${_formatValue(param.defaultValue, param.dartType)},',
  );
  ```
- **Origin of value:** Set by the template parser in `_extractDefaultValue` when building `RemoteConfigParameter` (template_parser.dart lines 66–75).

**Group parameters**

- **Where:** `code_generator.dart`, `_generateMainClass` (lines 300–314).
- **How:** For each group param it calls:
  ```dart
  final value = _extractGroupParameterValue(
    group.key,
    param,
    data.rawData,
  );
  // ...
  buffer.writeln(
    '      defaultValue: ${_formatValue(value, param.dartType)},',
  );
  ```
- **Origin of value:** `_extractGroupParameterValue` (lines 421–442) reads from `rawData['parameterGroups']?[groupKey]['parameters']?[param.key]['defaultValue']` and handles `useInAppDefault` (falls back to `rawData[param.key]`).

**Phase 3 hook**

- Add a single resolution step used by both code paths:
  - **Top-level:** Before emitting in `_generateStandardParam`, compute `resolved = resolveDefault(null, param.key, param.defaultValue, param.valueType)` and only use overrides when `valueType == BOOLEAN`; otherwise use `param.defaultValue`.
  - **Group:** Before emitting in the group loop, compute `resolved = resolveDefault(group.key, param.key, value, param.valueType)` (where `value` comes from `_extractGroupParameterValue`).
- So the “one-line” change is: **wherever we currently pass the template default into `_formatValue`, pass the result of `resolveDefault(...)` instead**, and implement `resolveDefault` to check the parsed overrides map first (for boolean params only), then return the template default.

---

## Summary

| Aspect | Finding |
|--------|--------|
| Group identity | Use template keys: `parameterGroups` key = group name, same as in JSON. |
| Defaults yaml shape | Nesting mirrors template: top-level keys = top-level params or group names; inside a group, keys = param keys. |
| Top-level default resolution | `_generateStandardParam` → `param.defaultValue`. |
| Group default resolution | `_extractGroupParameterValue(group.key, param, data.rawData)`. |
| Where to add overrides | New `resolveDefault(groupKey, paramKey, templateValue, valueType)` used in both `_generateStandardParam` and the group-param loop; only boolean overrides applied in this version. |
