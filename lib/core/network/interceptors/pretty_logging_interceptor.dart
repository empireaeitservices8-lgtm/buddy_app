import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// A colorful, highly readable console logger for Dio network requests and responses.
/// Active only when running in [kDebugMode].
class PrettyLoggingInterceptor extends Interceptor {
  /// Whether to print request/response headers.
  final bool logHeaders;

  /// Whether to print request payload body.
  final bool logRequestBody;

  /// Whether to print response payload body.
  final bool logResponseBody;

  /// Maximum characters of body to print (to avoid freezing console on huge payloads).
  final int maxBodyLength;

  // ANSI color codes
  static const String _reset = '\x1B[0m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _cyan = '\x1B[36m';
  // ignore: unused_field
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _gray = '\x1B[90m';

  PrettyLoggingInterceptor({
    this.logHeaders = true,
    this.logRequestBody = true,
    this.logResponseBody = true,
    this.maxBodyLength = 100000,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      options.extra['request_start_time'] =
          DateTime.now().millisecondsSinceEpoch;

      final method = options.method.toUpperCase();
      final url = options.uri.toString();

      final buffer = StringBuffer();
      buffer.writeln(
        '$_cyan┌────────────────── [HTTP REQUEST] ──────────────────$_reset',
      );
      buffer.writeln('$_cyan│$_reset $_magenta$method$_reset $url');

      // Query Parameters
      if (options.queryParameters.isNotEmpty) {
        buffer.writeln(
          '$_cyan│$_reset $_yellow[Query Parameters]:$_reset ${options.queryParameters}',
        );
      }

      // Headers
      if (logHeaders && options.headers.isNotEmpty) {
        buffer.writeln('$_cyan│$_reset $_yellow[Headers]:$_reset');
        options.headers.forEach((key, value) {
          buffer.writeln('$_cyan│$_reset   $key: $value');
        });
      }

      // Request Body
      if (logRequestBody && options.data != null) {
        buffer.writeln('$_cyan│$_reset $_yellow[Body]:$_reset');
        buffer.writeln(_formatBody(options.data, '$_cyan│$_reset   '));
      }

      buffer.writeln(
        '$_cyan└────────────────────────────────────────────────────$_reset',
      );
      debugPrint(buffer.toString());
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final startTime =
          response.requestOptions.extra['request_start_time'] as int?;
      final duration = startTime != null
          ? DateTime.now().millisecondsSinceEpoch - startTime
          : null;

      final statusCode = response.statusCode ?? 200;
      final method = response.requestOptions.method.toUpperCase();
      final path = response.requestOptions.uri.path;
      final color = statusCode >= 200 && statusCode < 300 ? _green : _yellow;

      final buffer = StringBuffer();
      buffer.writeln(
        '$color┌────────────────── [HTTP RESPONSE: $statusCode] ──────────────────$_reset',
      );
      buffer.writeln(
        '$color│$_reset $_magenta$method$_reset $path ${duration != null ? '($_yellow${duration}ms$_reset)' : ''}',
      );

      if (logResponseBody && response.data != null) {
        buffer.writeln('$color│$_reset $_yellow[Response Body]:$_reset');
        buffer.writeln(_formatBody(response.data, '$color│$_reset   '));
      }

      buffer.writeln(
        '$color└────────────────────────────────────────────────────$_reset',
      );
      debugPrint(buffer.toString());
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final startTime = err.requestOptions.extra['request_start_time'] as int?;
      final duration = startTime != null
          ? DateTime.now().millisecondsSinceEpoch - startTime
          : null;

      final statusCode = err.response?.statusCode;
      final method = err.requestOptions.method.toUpperCase();
      final url = err.requestOptions.uri.toString();

      final buffer = StringBuffer();
      buffer.writeln(
        '$_red┌────────────────── [HTTP ERROR: ${statusCode ?? 'NO_STATUS'}] ──────────────────$_reset',
      );
      buffer.writeln(
        '$_red│$_reset $_magenta$method$_reset $url ${duration != null ? '($_yellow${duration}ms$_reset)' : ''}',
      );
      String? displayMessage;
      if (err.response?.data is Map) {
        final data = err.response!.data as Map;
        displayMessage = data['message']?.toString() ??
            data['detail']?.toString() ??
            data['error']?.toString();
      }
      displayMessage ??= err.message?.split('\n').first;

      buffer.writeln(
        '$_red│$_reset $_red[Error]:$_reset $displayMessage',
      );

      if (err.response?.data != null) {
        buffer.writeln('$_red│$_reset $_yellow[Server Response]:$_reset');
        buffer.writeln(_formatBody(err.response?.data, '$_red│$_reset   '));
      }

      buffer.writeln(
        '$_red└────────────────────────────────────────────────────$_reset',
      );
      debugPrint(buffer.toString());
    }

    return handler.next(err);
  }

  /// Formats JSON/Map/List body with pretty indentation and line prefixing.
  String _formatBody(dynamic body, String prefix) {
    try {
      if (body is Map || body is List) {
        final encoder = const JsonEncoder.withIndent('  ');
        final prettyJson = encoder.convert(body);
        if (prettyJson.length > maxBodyLength) {
          final truncated = prettyJson.substring(0, maxBodyLength);
          return '${truncated.split('\n').map((line) => '$prefix$line').join('\n')}\n$prefix$_gray... [TRUNCATED - Payload exceeded $maxBodyLength chars]$_reset';
        }
        return prettyJson.split('\n').map((line) => '$prefix$line').join('\n');
      } else if (body is FormData) {
        final fields = body.fields
            .map((e) => '${e.key}: ${e.value}')
            .join('\n$prefix');
        final files = body.files
            .map((e) => '${e.key}: File(${e.value.filename})')
            .join('\n$prefix');
        return '$prefix[FormData]\n$prefix$fields\n$prefix$files';
      } else {
        final str = body.toString();
        if (str.length > maxBodyLength) {
          return '$prefix${str.substring(0, maxBodyLength)} $_gray... [TRUNCATED]$_reset';
        }
        return '$prefix$str';
      }
    } catch (_) {
      return '$prefix$body';
    }
  }

  /// Obfuscates sensitive authorization header string.
  String _obfuscateToken(String token) {
    if (token.length <= 15) return 'Bearer ***';
    return '${token.substring(0, 12)}...${token.substring(token.length - 4)}';
  }
}
