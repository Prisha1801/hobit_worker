import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hobit_worker/api_services/urls.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic details;
  ApiException(this.message, {this.statusCode, this.details});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      validateStatus: (_) => true,
      receiveDataWhenStatusError: true,
    ),
  )
    ..interceptors.addAll([
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: false,
          requestHeader: false,
        ),
    ]);

  static Dio get dio => _dio;

  static Response _handleResponse(Response res) {
    final httpCode = res.statusCode ?? 0;

    dynamic body = res.data;
    if (body is String) {
      try {
        body = jsonDecode(body);
      } catch (_) {}
    }
    // server message candidates
    String serverMsg = '';
    if (body is Map) {
      for (final c in [
        body['message'],
        body['msg'],
        body['error'],
        body['detail'],
      ]) {
        if (c is String && c.trim().isNotEmpty) {
          serverMsg = c.trim();
          break;
        }
      }
    } else if (res.statusMessage != null &&
        res.statusMessage!.trim().isNotEmpty) {
      serverMsg = res.statusMessage!.trim();
    }

    final int? bodyStatus =
    (body is Map && body['status_code'] is num)
        ? (body['status_code'] as num).toInt()
        : null;

    final isHttpOk = httpCode >= 200 && httpCode < 300;
    final isBodyOk = (body is Map && body['success'] == true);

    if (isHttpOk &&
        (isBodyOk ||
            bodyStatus == null ||
            (bodyStatus >= 200 && bodyStatus < 300))) {
      return res;
    }

    final codeToReport = bodyStatus ?? httpCode;
    final friendly =
    serverMsg.isNotEmpty ? serverMsg : _friendlyMessage(codeToReport);

    throw ApiException(
      friendly.isNotEmpty ? friendly : 'Unexpected error ($codeToReport)',
      statusCode: codeToReport,
      details: res.data,
    );
  }

  static String _friendlyMessage(int code, {String fallback = ''}) {
    switch (code) {
      case 400:
        return 'Bad request.';
      case 401:
        return 'Unauthorized.';
      case 403:
        return 'Forbidden.';
      case 404:
        return 'Resource ';
      case 408:
        return 'Request timeout.';
      case 413:
        return 'Payload';
      case 429:
        return 'requests ';
      case 500:
        return 'Server error. ';
      case 502:
      case 503:
      case 504:
        return 'Server unavailable. .';
      default:
        return fallback.isNotEmpty ? fallback : 'Error $code';
    }
  }

  static Never _mapDioError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          throw ApiException('Network timeout.');

        case DioExceptionType.cancel:
          throw ApiException('Request');

        case DioExceptionType.connectionError:
          if (e.error is SocketException) {
            throw ApiException('No internet connection.');
          }
          throw ApiException('Connection error.');

        // case DioExceptionType.badResponse:
        //   if (e.response != null) _handleResponse(e.response!);
        //   throw ApiException('Server responded with error.');
        case DioExceptionType.badResponse:
          if (e.response != null) {
            try {
              _handleResponse(e.response!);
            } catch (apiError) {
              if (apiError is ApiException) {
                throw apiError; // 🔥 rethrow original backend message
              }
            }
          }
          throw ApiException('Server responded with error.');

        case DioExceptionType.badCertificate:
          throw ApiException('Bad SSL certificate. ');

        case DioExceptionType.unknown:
          if (e.error is SocketException) {
            throw ApiException('No internet connection.');
          }
          throw ApiException(e.message ?? 'Unknown error.');
      }
    }
    throw ApiException('Something went wrong.');
  }

  // static Never _mapAndRethrow(Object e) {
  //   log('HTTP Error: $e');
  //   return _mapDioError(e);
  // }
  static Never _mapAndRethrow(Object e) {
    log('HTTP Error: $e');

    // 🔥 VERY IMPORTANT
    if (e is ApiException) {
      throw e; // <-- original backend message preserved
    }

    return _mapDioError(e);
  }


  static Future<Response> getRequest(
      String endpoint, {
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      final res = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(res);
    } catch (e) {
      return _mapAndRethrow(e);
    }
  }

  static Future<Response> postRequest(
      String endpoint,
      // Map<String, dynamic> data,
      dynamic data,
          {
        Options? options,
      }) async {
    try {
      final res = await _dio.post(endpoint, data: data, options: options);
      return _handleResponse(res);
    } catch (e) {
      return _mapAndRethrow(e);
    }
  }

  static Future<Response> putRequest(
      String endpoint,
      Map<String, dynamic> data, {
        Options? options,
      }) async {
    try {
      final res = await _dio.put(endpoint, data: data, options: options);
      return _handleResponse(res);
    } catch (e) {
      return _mapAndRethrow(e);
    }
  }

  static Future<Response> deleteRequest(
      String endpoint, {
        Map<String, dynamic>? data,
        Options? options,
      }) async {
    try {
      final res = await _dio.delete(endpoint, data: data, options: options);
      return _handleResponse(res);
    } catch (e) {
      return _mapAndRethrow(e);
    }
  }

  static Future<Response> postMultipart(String endpoint, FormData formData) async {
    try {
      return await _dio.post(
        endpoint.startsWith("http") ? endpoint : "$baseUrl$endpoint",
        data: formData,
        options: Options(
          headers: {
            "Accept": "application/json",
          },
        ),
      );
    } catch (e) {
      throw Exception("Multipart Error: $e");
    }
  }

}
