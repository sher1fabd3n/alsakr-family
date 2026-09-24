import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api_client.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.updateRequired,
    required this.latestVersion,
    required this.latestBuild,
    required this.currentVersion,
    required this.currentBuild,
    required this.downloadUrl,
    required this.message,
  });

  final bool updateRequired;
  final String latestVersion;
  final int latestBuild;
  final String currentVersion;
  final int currentBuild;
  final String downloadUrl;
  final String message;
}

class AppUpdateService {
  AppUpdateService(this._apiClient);

  final ApiClient _apiClient;

  Future<AppUpdateInfo?> check({String app = 'family'}) async {
    try {
      final package = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(package.buildNumber) ?? 0;
      final currentVersion = package.version;

      final response = await _apiClient.dio.get(
        '/api/mobile/app-version',
        queryParameters: {'app': app},
        options: Options(
          sendTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
        ),
      );

      final data = response.data;
      if (data is! Map) return null;

      final map = Map<String, dynamic>.from(data);
      final latestBuild = _asInt(map['latestBuild'] ?? map['LatestBuild']);
      final minBuild = _asInt(map['minBuild'] ?? map['MinBuild']);
      final requiredBuild = latestBuild > minBuild ? latestBuild : minBuild;
      if (requiredBuild <= 0) return null;

      final latestVersion = (map['latestVersion'] ?? map['LatestVersion'] ?? '').toString();
      final androidUrl = (map['androidUrl'] ?? map['AndroidUrl'] ?? '').toString();
      final iosUrl = (map['iosUrl'] ?? map['IosUrl'] ?? '').toString();
      final message = (map['message'] ?? map['Message'] ?? '').toString();
      final downloadUrl = Platform.isIOS
          ? (iosUrl.isNotEmpty ? iosUrl : androidUrl)
          : (androidUrl.isNotEmpty ? androidUrl : iosUrl);

      final updateRequired = currentBuild < requiredBuild;
      return AppUpdateInfo(
        updateRequired: updateRequired,
        latestVersion: latestVersion.isEmpty ? currentVersion : latestVersion,
        latestBuild: requiredBuild,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
        downloadUrl: downloadUrl,
        message: message.isEmpty
            ? 'يتوفر إصدار جديد من التطبيق. يجب التحديث للمتابعة.'
            : message,
      );
    } catch (_) {
      return null;
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
