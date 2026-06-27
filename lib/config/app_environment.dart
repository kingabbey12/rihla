/// Deployment environment for API endpoints and behaviour.
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromString(String value) {
    switch (value.toLowerCase()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      default:
        return AppEnvironment.development;
    }
  }

  bool get isDevelopment => this == AppEnvironment.development;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProduction => this == AppEnvironment.production;
}
