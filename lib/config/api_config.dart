import 'dart:io' show Platform;

class ApiConfig {
  // Set ke true untuk menggunakan domain production/tunnel
  static const bool isProduction = true;

  // Production base URL (Cloudflared tunnel)
  static const String _prodBaseUrl = 'https://magang-api.fwzdev.my.id/api';

  // Development base URLs
  static const String _devBaseUrl = 'http://localhost:8000/api'; // Web/Desktop dev
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  static const String _iosSimulatorUrl = 'http://127.0.0.1:8000/api'; // iOS simulator

  // Pilih base URL berdasarkan environment dan platform
  static String get baseUrl {
    if (isProduction) {
      return _prodBaseUrl;
    }

    // Development behavior
    if (Platform.isAndroid) {
      // Emulator Android gunakan 10.0.2.2, device fisik bisa gunakan adb reverse ke 127.0.0.1
      // Ganti ke 'http://127.0.0.1:8000/api' jika menggunakan adb reverse di perangkat fisik
      return _androidEmulatorUrl;
    }

    if (Platform.isIOS) {
      return _iosSimulatorUrl;
    }

    // Web/Desktop dev
    return _devBaseUrl;
  }

  // Timeout configurations (ms)
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Default headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String userEndpoint = '/auth/user';

  static const String productsEndpoint = '/products';
  static const String transactionsEndpoint = '/transactions';
  static const String paymentEndpoint = '/payment';
}
