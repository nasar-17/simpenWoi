import 'package:flutter_gemma/flutter_gemma.dart';

import 'function_gemma_tools.dart';

/// Validate the function schema before the permissive persistence codec runs.
/// Missing balances, fractional rupiah and invented fields must not become
/// valid financial actions through default values or numeric coercion.
bool isValidFunctionGemmaCall(FunctionCallResponse call) {
  final List<Tool> tools = functionGemmaTools
      .where((Tool tool) => tool.name == call.name)
      .toList(growable: false);
  if (tools.length != 1) return false;
  final Map<String, dynamic> schema = tools.single.parameters;
  final Map<String, dynamic> properties = schema['properties'] as Map<String, dynamic>;
  final List<String> required = schema['required'] as List<String>;
  if (required.any((String key) => !call.args.containsKey(key))) return false;
  for (final MapEntry<String, dynamic> entry in call.args.entries) {
    if (!properties.containsKey(entry.key)) return false;
    if (entry.value == null && !required.contains(entry.key)) continue;
    if (!_matches(entry.value, properties[entry.key] as Map<String, dynamic>)) {
      return false;
    }
  }
  return true;
}

bool _matches(Object? value, Map<String, dynamic> schema) {
  final bool correctType = switch (schema['type']) {
    'integer' => value is int,
    'string' => value is String,
    'boolean' => value is bool,
    'array' => value is List<Object?> && value.every((Object? item) =>
        _matches(item, schema['items'] as Map<String, dynamic>)),
    _ => false,
  };
  if (!correctType) return false;
  if (schema['enum'] case final List<Object?> allowed) {
    if (!allowed.contains(value)) return false;
  }
  if (schema['minimum'] case final num minimum) {
    if (value is num && value < minimum) return false;
  }
  if (schema['pattern'] case final String pattern) {
    if (value is String && !RegExp(pattern).hasMatch(value)) return false;
  }
  return true;
}
