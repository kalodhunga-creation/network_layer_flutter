import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConfig {
  ApiConfig._();
  static String? _authority;
  static const storage = FlutterSecureStorage();

  static Future<void> setAccessToken({required String accessToken}) async {
    await storage.write(key: 'access_token', value: accessToken);
  }

  static Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  static void setApiAuthority({required String baseUrl}) {
    _authority = baseUrl;
  }

  static Future<void> setRefreshToken({required String refreshToken}) async {
    await storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    return await storage.read(
      key: 'refresh_token',
    );
  }

  static String? getApiAuthority() {
    return _authority;
  }
}
