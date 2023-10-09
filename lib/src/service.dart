import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_http_cache_lts/dio_http_cache_lts.dart';
import 'package:network_layer/network_layer.dart';

enum HttpMethod { get, post, put, patch, delete }

typedef ResponseSerializer = dynamic Function(Map<String, dynamic> json);

// abstract class NetworkRequest {
//   static Future sendRequest(String requestUrl, HttpMethod method,
//       ResponseSerializer responseSerializer,
//       {Map<String, String>? queryParams,
//       Map<String, dynamic>? postData,
//       bool enableCache = false,
//       String? authority,
//       bool tokenRequired = true,
//       int cacheMaxMin = 15,
//       bool returnRaw = false});
// }

class ApiLayer {
  static Future sendRequest(String requestUrl, HttpMethod method,
      ResponseSerializer responseSerializer,
      {Map<String, String>? queryParams,
      Map<String, dynamic>? postData,
      bool enableCache = false,
      String? authority,
      bool tokenRequired = true,
      int cacheMaxMin = 15,
      bool returnRaw = false}) async {
    final HttpMiddleware httpMiddleware = HttpMiddleware();
    Response? httpResponse;
    DioError? dioError;
    var encodedBody = postData != null ? json.encode(postData) : null;

    authority ??= ApiConfig.getApiAuthority();
    logger.d(authority);

    try {
      final Dio http = await httpMiddleware.getHttpClient(
        authority,
        cache: enableCache,
        tokenRequired: tokenRequired,
      );

      switch (method) {
        case HttpMethod.get:
          httpResponse = await http.get(
            requestUrl,
            queryParameters: queryParams,
            options: enableCache
                ? buildCacheOptions(Duration(minutes: cacheMaxMin))
                : null,
          );
          break;

        case HttpMethod.post:
          httpResponse = await http.post(
            requestUrl,
            data: encodedBody,
            queryParameters: queryParams,
            options: enableCache
                ? buildCacheOptions(Duration(minutes: cacheMaxMin))
                : null,
          );
          break;

        case HttpMethod.put:
          httpResponse = await http.put(
            requestUrl,
            data: encodedBody,
            queryParameters: queryParams,
          );
          break;

        case HttpMethod.patch:
          httpResponse = await http.patch(
            requestUrl,
            data: encodedBody,
            queryParameters: queryParams,
          );
          break;

        case HttpMethod.delete:
          httpResponse = await http.delete(
            requestUrl,
            data: encodedBody,
            queryParameters: queryParams,
          );
          break;
      }
    } on DioError catch (error, stackTrace) {
      dioError = error;
      serviceErrorLogger(error, stackTrace);
      if (error.error is ApiError) {
        return Future.error(error.error);
      }
    }

    if (httpResponse != null && httpResponse.data != null) {
      bool isJson = (httpResponse.headers['content-type'] != null) &&
          httpResponse.headers['content-type']!.contains('application/json');

      final int? httpStatusCode = httpResponse.statusCode;
      final responseJson = httpResponse.data;
      if (returnRaw) {
        return {'responseJson': responseJson, 'httpStatusCode': httpStatusCode};
      }
      if (isJson && (httpStatusCode! ~/ 100 == 2)) {
        try {
          final responseObject = responseSerializer(responseJson);
          if (responseObject.status == "success") {
            return responseObject;
          }
          return Future.error(ApiError(
            httpStatusCode,
            dioError?.message,
            dioError?.type,
            responseObject.status,
            responseObject.msg,
            responseObject.error_code,
            responseObject.error_data,
          ));
        } catch (error, stackTrace) {
          serviceErrorLogger(error, stackTrace);
          return Future.error(ApiError(0));
        }
      }

      return Future.error(ApiError(
        httpStatusCode,
        dioError?.message,
        dioError?.type,
        httpResponse.statusMessage,
        httpResponse.data.toString(),
      ));
    }

    if (dioError != null) {
      logger.e("Dio Error is null");
      return Future.error(ApiError(0, dioError.message, dioError.type));
    }
    return Future.error(ApiError(0));
  }
}

void serviceErrorLogger(error, stackTrace) {
  List<String> ignoreErrorCodes = ["INVALID_TOKEN", "EXPIRED_REFRESH_TOKEN"];
  if (error is ApiError &&
      error.errorCode != null &&
      ignoreErrorCodes.contains(error.errorCode)) {
    logger.w(error);
  } else {
    logger.e(error);
  }
}
