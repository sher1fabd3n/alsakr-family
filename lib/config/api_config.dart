class ApiConfig {
  /// غيّر هذا العنوان ليطابق سيرفر SLSWebApp عند النشر.
  /// الإنتاج: https://alsakrschools.com
  /// للتطوير المحلي: --dart-define=API_BASE_URL=http://192.168.1.5:5286
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://alsakrschools.com',
  );

  static String get baseUrl {
    var url = _rawBaseUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
