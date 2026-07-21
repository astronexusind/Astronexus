import 'package:astro_tale/core/constants/api_constants.dart';
import 'package:astro_tale/services/api_services/api_client.dart';

class HoroscopeApi {
  static Future<Map<String, dynamic>> fetchHoroscope({
    required String sign,
    required String type,
  }) async {
    final normalizedType = type.trim().toLowerCase();
    Object? lastError;

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final endpoint = "/api/unified/my-horoscope?type=$normalizedType&day=TODAY";
        final responseData = await ApiClient().get(endpoint);

        final parsed = _parseBody(responseData, normalizedType);
        final text = parsed["horoscope"]?.toString().trim() ?? "";

        if (text.isNotEmpty) {
          return parsed;
        }
        lastError = Exception("Horoscope payload was empty");
      } catch (e) {
        //print("Horoscope API error: $e");
        lastError = e;
      }
    }

    return _fallback(
      sign: sign,
      type: normalizedType,
      error: lastError,
    );
  }

  static Map<String, dynamic> _parseBody(Map<String, dynamic> decoded, String type) {
    final root = _asMap(decoded);
    final rootData = _asMap(root["data"]);
    final nestedData = _asMap(rootData["data"]);

    final fromRootType = _asMap(root[type]);
    final fromDataType = _asMap(rootData[type]);
    final fromNestedType = _asMap(nestedData[type]);
    
    // Fallback directly to rootData or root if nested maps are empty
    final scoped = fromDataType.isNotEmpty
        ? fromDataType
        : (fromRootType.isNotEmpty
              ? fromRootType
              : (fromNestedType.isNotEmpty
                    ? fromNestedType
                    : (nestedData.isNotEmpty 
                        ? nestedData 
                        : (rootData.isNotEmpty ? rootData : root))));

    final title = _titleFor(type, scoped);
    final horoscope = _extractText(scoped);

    if (type == "monthly") {
      final nestedScoped = _asMap(scoped["data"]);
      final deepScoped = _asMap(nestedScoped["data"]);
      return {
        "title": title,
        "horoscope": horoscope,
        "extra": {
          "standout_days": _asStringList(
            scoped["standout_days"] ??
                scoped["standoutDays"] ??
                nestedScoped["standout_days"] ??
                nestedScoped["standoutDays"] ??
                deepScoped["standout_days"] ??
                deepScoped["standoutDays"] ??
                nestedData["standout_days"] ??
                nestedData["standoutDays"],
          ),
          "challenging_days": _asStringList(
            scoped["challenging_days"] ??
                scoped["challengingDays"] ??
                nestedScoped["challenging_days"] ??
                nestedScoped["challengingDays"] ??
                deepScoped["challenging_days"] ??
                deepScoped["challengingDays"] ??
                nestedData["challenging_days"] ??
                nestedData["challengingDays"],
          ),
        },
      };
    }

    return {"title": title, "horoscope": horoscope, "extra": null};
  }

  static String _titleFor(String type, Map<String, dynamic> data) {
    final nested = _asMap(data["data"]);
    final deepNested = _asMap(nested["data"]);
    switch (type) {
      case "daily":
        return _firstNonEmptyString(<dynamic>[
          data["date"],
          nested["date"],
          deepNested["date"],
          data["title"],
          nested["title"],
          deepNested["title"],
        ], "Today");
      case "weekly":
        return _firstNonEmptyString(<dynamic>[
          data["week"],
          nested["week"],
          deepNested["week"],
          data["title"],
          nested["title"],
          deepNested["title"],
        ], "This Week");
      case "monthly":
        return _firstNonEmptyString(<dynamic>[
          data["month"],
          nested["month"],
          deepNested["month"],
          data["title"],
          nested["title"],
          deepNested["title"],
        ], "This Month");
      default:
        return _firstNonEmptyString(<dynamic>[
          data["title"],
          nested["title"],
          deepNested["title"],
        ]);
    }
  }

  static String _extractText(Map<String, dynamic> data) {
    final nested = _asMap(data["data"]);
    final deepNested = _asMap(nested["data"]);
    return _firstNonEmptyString(<dynamic>[
      data["horoscope_data"],
      data["horoscope"],
      data["prediction"],
      data["text"],
      data["content"],
      data["message"],
      nested["horoscope_data"],
      nested["horoscope"],
      nested["prediction"],
      nested["text"],
      nested["content"],
      nested["message"],
      deepNested["horoscope_data"],
      deepNested["horoscope"],
      deepNested["prediction"],
      deepNested["text"],
      deepNested["content"],
      deepNested["message"],
    ]);
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    if (value == null) {
      return const <String>[];
    }
    final single = value.toString().trim();
    if (single.isEmpty) {
      return const <String>[];
    }
    return <String>[single];
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    return <String, dynamic>{};
  }

  static String _firstNonEmptyString(
    List<dynamic> values, [
    String fallback = "",
  ]) {
    for (final value in values) {
      final text = value?.toString().trim() ?? "";
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }

  static Map<String, dynamic> _fallback({
    required String sign,
    required String type,
    Object? error,
  }) {
    final normalizedSign = sign.toUpperCase();
    
    // If the backend throws our 400 error because the chart is missing, 
    // let's show a user-friendly message asking them to complete their profile.
    if (error != null && error.toString().contains("Birth chart not generated")) {
      return {
        "title": "Action Required",
        "horoscope": "Please complete your birth profile to unlock your personalized $normalizedSign horoscope.",
        "extra": null,
      };
    }

    final unavailable = error == null ? "" : " (network)";
    switch (type) {
      case "daily":
        return {
          "title": "Today",
          "horoscope":
              "Horoscope not available today for $normalizedSign$unavailable",
          "extra": null,
        };
      case "weekly":
        return {
          "title": "This Week",
          "horoscope":
              "Horoscope not available this week for $normalizedSign$unavailable",
          "extra": null,
        };
      case "monthly":
        return {
          "title": "This Month",
          "horoscope":
              "Horoscope not available this month for $normalizedSign$unavailable",
          "extra": {
            "standout_days": <String>[],
            "challenging_days": <String>[],
          },
        };
      default:
        return {
          "title": "",
          "horoscope": "Horoscope not available",
          "extra": null,
        };
    }
  }
}