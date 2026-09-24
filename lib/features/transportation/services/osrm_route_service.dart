import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';

class OsrmRouteResult {
  const OsrmRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  String get distanceText {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} كم';
    }
    return '${distanceMeters.round()} م';
  }

  String get durationText {
    final minutes = (durationSeconds / 60).round().clamp(1, 999);
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '$h س' : '$h س $m د';
    }
    return '$minutes د';
  }
}

/// مسارات القيادة عبر OSRM العام (نفس أسلوب تطبيق users_app).
class OsrmRouteService {
  OsrmRouteService({Dio? dio}) : _dio = dio ?? Dio();

  static const _baseUrl = 'https://router.project-osrm.org/route/v1/driving';
  static const refreshMinDistanceMeters = 60.0;

  final Dio _dio;
  final PolylinePoints _decoder = PolylinePoints();

  Future<OsrmRouteResult?> fetchRoute(LatLng origin, LatLng destination) async {
    final url =
        '$_baseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=polyline';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      final data = response.data;
      if (data == null) return null;
      final code = data['code']?.toString();
      if (code != null && code.toLowerCase() != 'ok') return null;

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final distance = (route['distance'] as num?)?.toDouble();
      final duration = (route['duration'] as num?)?.toDouble();
      final geometry = route['geometry']?.toString();
      if (distance == null || duration == null || geometry == null) return null;

      final decoded = _decoder.decodePolyline(geometry);
      final points = decoded
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList(growable: false);

      if (points.length < 2) {
        return OsrmRouteResult(
          points: [origin, destination],
          distanceMeters: distance,
          durationSeconds: duration,
        );
      }

      return OsrmRouteResult(
        points: points,
        distanceMeters: distance,
        durationSeconds: duration,
      );
    } catch (_) {
      return OsrmRouteResult(
        points: [origin, destination],
        distanceMeters: const Distance().as(LengthUnit.Meter, origin, destination),
        durationSeconds: 0,
      );
    }
  }

  static bool shouldRefreshRoute({
    required LatLng? lastOrigin,
    required LatLng currentOrigin,
  }) {
    if (lastOrigin == null) return true;
    final moved = const Distance().as(LengthUnit.Meter, lastOrigin, currentOrigin);
    return moved >= refreshMinDistanceMeters;
  }
}
