/// Configuracion global de la aplicacion LYP INNOVA
/// 
/// Este archivo contiene variables de estado global que se usan
/// en toda la aplicacion para verificar servicios criticos
library;

/// Indica si Firebase se inicializo correctamente
/// 
/// - true: Firebase esta listo para usar (Auth, Firestore, Storage, etc.)
/// - false: Firebase no pudo inicializarse (sin internet o configuracion incorrecta)
/// 
/// Esta variable se establece en main.dart durante la inicializacion
bool firebaseReady = false;

/// Version de la aplicacion
const String appVersion = '1.0.0';

/// Nombre de la aplicacion
const String appName = 'LYP INNOVA';

/// Configuracion de entorno
enum Environment {
  development,
  staging,
  production,
}

/// Entorno actual de la aplicacion
const Environment currentEnvironment = Environment.production;

/// Configuracion de timeouts (en segundos)
class TimeoutConfig {
  static const int networkTimeout = 30;
  static const int uploadTimeout = 60;
  static const int downloadTimeout = 120;
}

/// Configuracion de limites
class LimitsConfig {
  static const int maxImageSizeMB = 10;
  static const int maxFileUploadMB = 25;
  static const int maxProjectsPerUser = 100;
}

/// URLs de la aplicacion (si se necesitan)
class AppUrls {
  static const String privacyPolicy = 'https://lypinnova.com/privacy';
  static const String termsOfService = 'https://lypinnova.com/terms';
  static const String support = 'https://lypinnova.com/support';
}

/// Configuracion de cache
class CacheConfig {
  static const int maxCacheAgeDays = 7;
  static const bool enableOfflineMode = true;
}