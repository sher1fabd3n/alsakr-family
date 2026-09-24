import 'package:latlong2/latlong.dart';

class MapLineUtils {
  static LatLng? sanitize(LatLng? point) {
    if (point == null) return null;
    final lat = point.latitude;
    final lon = point.longitude;
    if (!lat.isFinite || !lon.isFinite) return null;
    if (lat.abs() < 0.01 && lon.abs() < 0.01) return null;
    if (lat < -85 || lat > 85 || lon < -180 || lon > 180) return null;
    return point;
  }

  static double distanceMeters(LatLng from, LatLng to) =>
      const Distance().as(LengthUnit.Meter, from, to);

  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} كم';
    }
    return '${meters.round()} م';
  }

  static String? etaFromDistance(double meters, {double speedKmh = 30}) {
    if (meters <= 0 || speedKmh <= 0) return null;
    final hours = (meters / 1000) / speedKmh;
    final minutes = (hours * 60).ceil().clamp(1, 999);
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '$h س' : '$h س $m د';
    }
    return '$minutes د';
  }
}
