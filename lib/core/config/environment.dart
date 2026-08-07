/// Defines the build flavor / environment of the app.
enum Flavor { mock, dev, prod }

/// Centralised environment configuration.
///
/// Switch [currentFlavor] at app startup (e.g. via --dart-define) to control
/// which backend the app talks to.
class Environment {
  Environment._();

  /// The active flavor. Defaults to [Flavor.mock] for safe local development.
  static Flavor currentFlavor = Flavor.mock;

  /// Whether the app is running against the mock data layer.
  static bool get isMock => currentFlavor == Flavor.mock;

  /// The base URL for API requests.
  ///
  /// Returns an empty string in mock mode (no real network calls are made).
  static String get baseUrl {
    switch (currentFlavor) {
      case Flavor.mock:
        return '';
      case Flavor.dev:
        return 'http://127.0.0.1:8000/api/v1';
      case Flavor.prod:
        return 'https://api.zindagiplus.com/api/v1';
    }
  }
}
