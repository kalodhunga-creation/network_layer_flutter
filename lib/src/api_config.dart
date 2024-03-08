import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:network_layer/network_layer.dart';

class ApiConfig {
  static final ApiConfig _instance = ApiConfig._internal();
  late FlutterSecureStorage storage;

  /// Private constructor, not async
  ApiConfig._internal() {
    storage = const FlutterSecureStorage();
  }

  /// static singleton instance getter, not async
  static ApiConfig get getInstance => _instance;

  static String? _authority;

  Future<void> setAccessToken({required String accessToken}) async {
    await storage.write(key: 'access_token', value: accessToken);
  }

  Future<String?> getAccessToken() async {
    return (await storage.read(key: 'access_token'));
  }

  void setApiAuthority({required String baseUrl}) {
    _authority = baseUrl;
  }

  Future<void> setRefreshToken({required String refreshToken}) async {
    await storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> setAppInitialize({required bool value}) async {
    await storage.write(key: 'app_initialize', value: "$value");
  }

  Future<String?> getRefreshToken() async {
    return await storage.read(
      key: 'refresh_token',
    );
  }

  String? getApiAuthority() {
    return _authority;
  }

  Future<bool> get isAuthenticated async {
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      return true;
    } else {
      logger.e('Auth token ${token ?? 'not found.'}');
    }
    return false;
  }

  Future<bool> get isAppInitialize async {
    final isInitialize = await storage.read(key: 'app_initialize');
    if (isInitialize == 'true') {
      return true;
    }
    logger.e('Auth token ${isInitialize ?? 'not found.'}');

    return false;
  }

  void clearApiConfig() async {
    await storage.deleteAll();
  }
}
