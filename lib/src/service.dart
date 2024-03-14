import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_http_cache_lts/dio_http_cache_lts.dart';
import 'package:network_layer/network_layer.dart';

enum HttpMethod { get, post, put, patch, delete }

enum DataRequestMethod {
  GET,
  POST,
  PUT,
  PATCH,
  DELETE,
}

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
  static Future sendRequest(String requestUrl, DataRequestMethod method,
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

    authority ??= secureStorage.getApiAuthority();
    logger.d(authority);

    try {
      final Dio http = await httpMiddleware.getHttpClient(
        authority,
        cache: enableCache,
        tokenRequired: tokenRequired,
      );

      switch (method) {
        case DataRequestMethod.GET:
          httpResponse = await http.get(
            requestUrl,
            queryParameters: queryParams,
            options: enableCache
                ? buildCacheOptions(Duration(minutes: cacheMaxMin))
                : null,
          );
          break;

        case DataRequestMethod.POST:
          httpResponse = await http.post(
            requestUrl,
            data: encodedBody,
            queryParameters: queryParams,
            options: enableCache
                ? buildCacheOptions(Duration(minutes: cacheMaxMin))
                : null,
          );
          break;

        case DataRequestMethod.PUT:
          httpResponse = await http.put(
            requestUrl,
            data: encodedBody,
            queryParameters: queryParams,
          );
          break;

        case DataRequestMethod.PATCH:
          httpResponse = await http.patch(
            requestUrl,
            data: encodedBody,
            queryParameters: queryParams,
          );
          break;

        case DataRequestMethod.DELETE:
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
          logger.d(responseJson);
          final responseObject = responseSerializer(responseJson);
          return responseObject;
          // if (responseObject.status == "success") {
          //   return responseObject;
          // }
          // return Future.error(ApiError(
          //   httpStatusCode,
          //   dioError?.message,
          //   dioError?.type,
          //   responseObject.status,
          //   responseObject.message,
          //   responseObject.error_code,
          //   responseObject.error_data,
          // ));
        } catch (error, stackTrace) {
          serviceErrorLogger(error, stackTrace);
          return Future.error(ApiError(
            httpStatusCode,
            dioError?.message,
            dioError?.type,
            httpResponse.statusMessage,
            httpResponse.data.toString(),
          ));
        }
      } else {
        logger.d(responseJson);
        final responseObject = responseSerializer(responseJson);
        return Future.error(ApiError(
          httpStatusCode,
          dioError?.message,
          dioError?.type,
          responseObject.status,
          responseObject.message,
          responseObject.error_code,
          responseObject.error_data,
        ));
      }
    }


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
