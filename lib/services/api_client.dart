import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';

class ApiClient {
  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
            ),
        _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
            sendTimeout: ApiConfig.connectTimeout,
            followRedirects: true,
            maxRedirects: 5,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Accept-Language': 'ar',
            },
          ),
        ) {
    final adapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.idleTimeout = const Duration(seconds: 20);
        client.connectionTimeout = ApiConfig.connectTimeout;
        client.userAgent = 'Mozilla/5.0 AlSakrFamily/1.0';
        // كروم يجلب الشهادة الوسيطة تلقائياً، وDart لا يفعل ذلك على بعض الأجهزة.
        client.badCertificateCallback = (cert, host, port) =>
            _isSchoolCertificate(host, cert);
        return client;
      },
      validateCertificate: (cert, host, port) {
        if (cert == null) return false;
        return _isSchoolCertificate(host, cert);
      },
    );
    _dio.httpClientAdapter = adapter;
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.connectTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Accept-Language': 'ar',
        },
      ),
    )..httpClientAdapter = adapter;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.data is FormData) {
            options.headers.remove(Headers.contentTypeHeader);
            options.headers.remove('Content-Type');
          }
          final path = options.path.toLowerCase();
          final isLogin = path.contains('/login');
          if (!isLogin) {
            final token = await readToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (!_shouldRefresh(error)) {
            return handler.next(error);
          }
          final refreshed = await tryRefreshSession();
          if (!refreshed) {
            return handler.next(error);
          }
          final req = error.requestOptions;
          req.extra['_retriedAfterRefresh'] = true;
          try {
            final token = await readToken();
            if (token != null && token.isNotEmpty) {
              req.headers['Authorization'] = 'Bearer $token';
            }
            final response = await _dio.fetch(req);
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        },
      ),
    );
  }

  static const _tokenKey = 'auth_token';

  final Dio _dio;
  late final Dio _refreshDio;
  final FlutterSecureStorage _storage;
  Future<bool>? _refreshInFlight;
  String? _memoryToken;

  Dio get dio => _dio;

  bool _shouldRefresh(DioException error) {
    if (error.response?.statusCode != 401) return false;
    if (error.requestOptions.extra['_retriedAfterRefresh'] == true) return false;
    final path = error.requestOptions.path.toLowerCase();
    if (path.contains('/login') || path.contains('/auth/refresh')) return false;
    return true;
  }

  Future<bool> tryRefreshSession() {
    return _refreshInFlight ??= _refreshSession().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _refreshSession() async {
    try {
      final token = await readToken();
      if (token == null || token.isEmpty) return false;
      final response = await _refreshDio.post(
        '/api/communication/auth/refresh',
        data: {'token': token},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      final data = response.data;
      final next = data is Map ? (data['token'] ?? data['Token'])?.toString() : null;
      if (next == null || next.isEmpty) return false;
      await saveToken(next);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveToken(String token) async {
    _memoryToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}
  }

  Future<String?> readToken() async {
    if (_memoryToken != null && _memoryToken!.isNotEmpty) return _memoryToken;
    try {
      final stored = await _storage.read(key: _tokenKey);
      if (stored != null && stored.isNotEmpty) {
        _memoryToken = stored;
      }
      return stored;
    } catch (_) {
      return _memoryToken;
    }
  }

  Future<void> clearToken() async {
    _memoryToken = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }

  Future<void> writeSecure(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> readSecure(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteSecure(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  String extractErrorMessage(DioException error) {
    final data = error.response?.data;
    final fromJson = _messageFromBody(data);
    if (fromJson != null && fromJson.isNotEmpty) return fromJson;

    final statusCode = error.response?.statusCode;
    final inner = '${error.error ?? ''} ${error.message ?? ''}'.toLowerCase();

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'انتهت مهلة الاتصال بالسيرفر. حاول مرة أخرى مع شبكة مستقرة.';
      case DioExceptionType.connectionError:
        return 'تعذر الاتصال بالسيرفر. تأكد من الإنترنت وأن الموقع https://alsakrschools.com يعمل.';
      case DioExceptionType.badCertificate:
        return 'تعذر التحقق من شهادة الموقع على هذا الجهاز. حدّث التطبيق وأعد المحاولة.';
      default:
        break;
    }

    if (inner.contains('handshake') ||
        inner.contains('certificate') ||
        inner.contains('tls') ||
        inner.contains('ssl')) {
      return 'تعذر إنشاء اتصال آمن على هذا الجهاز. تأكد من الإنترنت وحدّث التطبيق.';
    }
    if (inner.contains('socket') ||
        inner.contains('failed host lookup') ||
        inner.contains('network is unreachable') ||
        inner.contains('connection refused')) {
      return 'لا يمكن الوصول إلى السيرفر من هذا الجهاز. تحقق من الإنترنت وعنوان الموقع.';
    }

    if (statusCode == 500) {
      return 'السيرفر أرجع خطأ داخلي. أعد رفع نسخة الويب بعد التعديلات مع الإبقاء على إعدادات الاستضافة.';
    }
    if (statusCode == 401) {
      return 'بيانات الدخول غير صحيحة. استخدم اسم المستخدم وكلمة مرور ولي الأمر.';
    }
    if (statusCode == 404 || statusCode == 405) {
      return 'مسار تسجيل الدخول غير موجود على السيرفر. تأكد أن نسخة الويب المنشورة هي الأحدث.';
    }
    if (data is String && data.contains('An error occurred')) {
      return 'الموقع على السيرفر توقف بخطأ. أعد رفع المشروع بدون استبدال ملف إعدادات الاستضافة.';
    }
    if (statusCode != null) {
      return 'تعذر تسجيل الدخول (رمز $statusCode). حاول مرة أخرى.';
    }
    return 'تعذر الاتصال بخدمة الدخول. تحقق من الإنترنت ثم حاول مرة أخرى.';
  }

  static String? _messageFromBody(dynamic data) {
    if (data is Map) {
      final message = data['message'] ?? data['Message'];
      if (message != null) return message.toString();
    }
    if (data is String && data.trim().isNotEmpty) {
      final trimmed = data.trim();
      if (trimmed.startsWith('{') && trimmed.contains('message')) {
        final match = RegExp(r'"[Mm]essage"\s*:\s*"([^"]+)"').firstMatch(trimmed);
        if (match != null) return match.group(1);
      }
    }
    return null;
  }

  static const _trustedHosts = {
    'alsakrschools.com',
    'www.alsakrschools.com',
  };

  static bool isTrustedSchoolHost(String host, X509Certificate cert) =>
      _isSchoolCertificate(host, cert);

  static bool _isSchoolCertificate(String host, X509Certificate cert) {
    final normalized = host.toLowerCase().trim();
    if (!_trustedHosts.contains(normalized)) return false;

    final now = DateTime.now().toUtc();
    if (now.isBefore(cert.startValidity.toUtc()) ||
        now.isAfter(cert.endValidity.toUtc())) {
      return false;
    }

    return true;
  }
}
