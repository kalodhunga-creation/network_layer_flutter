import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:network_layer/network_layer.dart';

class ApiConfig {
  ApiConfig._();
  static String? _authority;
  static const storage = FlutterSecureStorage();

  static Future<void> setAccessToken({required String accessToken}) async {
    await storage.write(key: 'access_token', value: accessToken);
  }

  static Future<String?> getAccessToken() async {
    return (await storage.read(key: 'access_token'));
  }

  static void setApiAuthority({required String baseUrl}) {
    _authority = baseUrl;
  }

  static Future<void> setRefreshToken({required String refreshToken}) async {
    await storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<void> setAppInitialize({required bool value}) async {
    await storage.write(key: 'app_initialize', value: "$value");
  }

  static Future<String?> getRefreshToken() async {
    return await storage.read(
      key: 'refresh_token',
    );
  }

  static String? getApiAuthority() {
    return _authority;
  }

  static Future<bool> get isAuthenticated async {
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      return true;
    }
    logger.e('Auth token ${token ?? 'not found.'}');

    return false;
  }

  static Future<bool> get isAppInitialize async {
    final isInitialize = await storage.read(key: 'app_initialize');
    if (isInitialize == 'true') {
      return true;
    }
    logger.e('Auth token ${isInitialize ?? 'not found.'}');

    return false;
  }

  static void clearApiConfig() async {
    await storage.deleteAll();
  }
}
