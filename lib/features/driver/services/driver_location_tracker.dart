import '../services/driver_service.dart';

/// تتبع موقع السائق غير مفعّل في تطبيق ولي الأمر.
/// الموقع المباشر يُرسل من تطبيق السائق فقط.
class DriverLocationTracker {
  DriverLocationTracker(this._driverService);

  // ignore: unused_field
  final DriverService _driverService;

  Future<void> start(int tripId) async {}

  Future<void> stop() async {}
}
