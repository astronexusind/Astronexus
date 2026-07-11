class AgoraConstants {
  const AgoraConstants._();

  /// Your Agora project's App ID (from the Agora Console — Project Management).
  /// This is safe to ship client-side; it is NOT a secret. The App
  /// Certificate is the secret — that stays server-side only, in
  /// backend/.env, and is used to sign tokens in backend/src/config/agora.js.
  static const String appId = "7d451fa408b4465f8f818f2526457592";
}