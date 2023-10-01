import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:network_layer/network_layer.dart';

var logger = Logger();

class HttpMiddleware {
  Dio dio = Dio();

  Future<Dio> getHttpClient(
    baseUrl, {
    responseSerializer,
    cache = false,
    cacheAgeMin = 15,
    bool tokenRequired = true,
  }) async {
    String? accessToken = await ApiConfig.getAccessToken();
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = 60000; //60s
    dio.options.receiveTimeout = 60000;

    dio.interceptors.add(QueuedInterceptorsWrapper(onRequest:
        (RequestOptions options, RequestInterceptorHandler handler) async {
      // Do something before request is sent
      print("token for opn $accessToken");
      // Do something before request is sent

      String requestUrl = options.baseUrl + options.path;
      logger.d(requestUrl);
      if (accessToken!.isEmpty) {
        return handler.reject(DioError(
            requestOptions: RequestOptions(
              path: options.path,
            ),
            type: DioErrorType.other,
            error: ApiError(404, "Token is null"))); //continue
      }
      if (tokenRequired) {
        options.headers['Authorization'] = 'Token $accessToken';
      }
      return handler.next(options); //continue
    }, onResponse:
        (Response<dynamic> response, ResponseInterceptorHandler handler) async {
      // Do something with response data

      return handler.next(response); // continue
    }, onError: (DioError error, ErrorInterceptorHandler handler) async {
      if (error.response?.statusCode == 401) {
        // If a 401 response is received, refresh the access token
        String? oldRefreshToken = await ApiConfig.getRefreshToken();
        String? oldAccessToken = await ApiConfig.getAccessToken();

        String newAccessToken = ""; //await refreshToken();
        String newRefreshToken = "";
        ApiConfig.setAccessToken(accessToken: newAccessToken);
        ApiConfig.setRefreshToken(refreshToken: newRefreshToken);
        // Update the request header with the new access token

        final originResult = await dio.fetch(error.requestOptions);
        if (originResult.statusCode != null &&
            originResult.statusCode! ~/ 100 == 2) {
          return handler.resolve(originResult);
        } else {
          return handler.reject(error);
        }
        // return handler.resolve(await dio.fetch(error.requestOptions));
      }
      return handler.next(error);
    }));
    return dio;
  }
}
