class ApiConstants {
  const ApiConstants._();

  // NOTE: use "localhost" when backend + Flutter web/Chrome run on the same
  // machine (the normal dev setup). Only switch this to your machine's LAN
  // IP (e.g. via `ipconfig getifaddr en0` on Mac) if you specifically need
  // to test from a physical phone over the same Wi-Fi network — and even
  // then, that IP will change whenever you switch networks or machines, so
  // don't leave it hardcoded long-term.
  static const String baseUrl = "http://localhost:8001";
  static const String userBaseUrl = "$baseUrl/user";
  static const String authBaseUrl = baseUrl;

  static const String horoscopeBaseUrl = "$baseUrl/api/unified/horoscope";
  static const String legacyHoroscopeBaseUrl = "$baseUrl/api/unified/horoscope";

  static const String birthChartApi = "$baseUrl/api/unified/birth-chart";
  static const String legacyBirthChartApi = "$baseUrl/api/unified/birth-chart";
  static const String birthChartGenerateApi =
      "$baseUrl/api/birthchart/generate";
  static const List<String> birthChartImageBaseCandidates = <String>[
    baseUrl,
    "https://backend.astronexus.in",
  ];

  static const String chatbotAskApi = "$baseUrl/api/unified/mati-chat";
  static const String geocodeApi =
      "https://maps.googleapis.com/maps/api/geocode/json";
  static const String citySearchApi = "https://photon.komoot.io/api/";
}