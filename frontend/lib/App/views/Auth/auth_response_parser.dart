Map<String, dynamic> unwrapAuthResponse(dynamic decoded) {
  if (decoded is Map<String, dynamic>) {
    final nested = decoded['data'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }
    if (nested is Map) {
      return nested.map((key, value) => MapEntry(key.toString(), value));
    }
    return decoded;
  }

  if (decoded is Map) {
    final mapped = decoded.map((key, value) => MapEntry(key.toString(), value));
    final nested = mapped['data'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }
    if (nested is Map) {
      return nested.map((key, value) => MapEntry(key.toString(), value));
    }
    return mapped;
  }

  return <String, dynamic>{};
}

Map<String, dynamic> asStringKeyMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }
  return <String, dynamic>{};
}

String extractAuthError(dynamic decoded, {String fallback = 'Request failed'}) {
  if (decoded is Map) {
    final mapped = decoded.map((key, value) => MapEntry(key.toString(), value));
    final message = mapped['message']?.toString().trim() ?? '';
    if (message.isNotEmpty) {
      return message;
    }

    final error = mapped['error']?.toString().trim() ?? '';
    if (error.isNotEmpty) {
      return error;
    }

    final errors = mapped['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors.first.toString();
    }
  }

  return fallback;
}
