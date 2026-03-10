import 'dart:convert';

bool boolFromJson(dynamic value) {
  if (value is int) {
    return value == 1;
  } else if (value is bool) {
    return value;
  }
  return false;
}

bool isPrimitive(dynamic value) {
  return value is int ||
      value is num ||
      value is double ||
      value is String ||
      value is bool ||
      value == null;
}

Map<String, dynamic> objectToDbData<T>(
  T obj,
  Map<String, dynamic> Function(T) toJson,
) {
  final json = toJson(obj);
  final formattedJson = json.map(
    (key, value) => MapEntry(key, _formatValue(value)),
  );
  return formattedJson;
}

dynamic _formatValue(Object? obj) {
  if (!isPrimitive(obj)) {
    return jsonEncode(obj);
  }
  return obj;
}

dynamic _formatCollectionString(dynamic value) {
  if (value is String) {
    try {
      if (value.startsWith('{') && value.endsWith('}')) {
        return jsonDecode(value);
      } else if (value.startsWith('[') && value.endsWith(']')) {
        dynamic decoded = jsonDecode(value);
        return decoded;
      }
      // ignore: empty_catches
    } catch (ignore) {}
  }
  return value;
}

T dbDataToObj<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) fromJson,
) {
  json = json.map(
    (key, value) => MapEntry(key, _formatCollectionString(value)),
  );
  // final decodedJson = jsonDecode(jsonEncode(json));
  return fromJson(json);
}
