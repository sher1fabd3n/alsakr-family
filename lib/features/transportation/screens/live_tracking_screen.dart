import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/api_client.dart';
import '../models/transportation_models.dart';
import '../services/bus_tracking_signalr_service.dart';
import '../services/map_line_utils.dart';
import '../services/osrm_route_service.dart';
import '../services/transportation_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, this.studentId, this.tripId});

  final int? studentId;
  final int? tripId;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  /// زوم شارع — تظهر أسماء الشوارع على بلاط OSM عند 16+
  static const _streetZoom = 17.5;
  /// دسوق — كفر الشيخ (افتراضي عند غياب GPS)
  static const _defaultCenter = LatLng(31.1294, 30.6472);

  final _mapController = MapController();
  final _signalR = BusTrackingSignalRService();
  final _osrm = OsrmRouteService();

  LiveTrackingData? _tracking;
  LatLng? _busLocation;
  LatLng? _lastRouteOrigin;
  List<LatLng> _connectionLine = const [];
  List<LatLng> _roadRoutePoints = const [];
  String? _liveDistanceText;
  String? _liveDurationText;
  bool _loading = true;
  bool _requestingRoute = false;
  bool _mapReady = false;
  bool _followBus = true;
  String? _error;
  bool _isNoActiveTrip = false;
  Timer? _pollTimer;
  int _mapGeneration = 0;

  LatLng? get _pickupLatLng {
    final t = _tracking;
    if (t?.studentPickupLatitude == null || t?.studentPickupLongitude == null) {
      return null;
    }
    return MapLineUtils.sanitize(LatLng(t!.studentPickupLatitude!, t.studentPickupLongitude!));
  }

  LatLng? get _routeTarget => _pickupLatLng;

  LatLng get _mapCenter {
    final bus = MapLineUtils.sanitize(_busLocation);
    if (bus != null) return bus;
    if (_pickupLatLng != null) return _pickupLatLng!;
    for (final stop in _tracking?.stops ?? const <RouteStopData>[]) {
      final point = MapLineUtils.sanitize(LatLng(stop.latitude, stop.longitude));
      if (point != null) return point;
    }
    return _defaultCenter;
  }

  void _syncConnectionLine() {
    final bus = MapLineUtils.sanitize(_busLocation);
    final target = _routeTarget;
    if (bus == null || target == null) return;

    final meters = MapLineUtils.distanceMeters(bus, target);
    setState(() {
      _connectionLine = [bus, target];
      if (_roadRoutePoints.isEmpty) {
        _liveDistanceText = MapLineUtils.formatDistance(meters);
        _liveDurationText = MapLineUtils.etaFromDistance(meters);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final transport = context.read<TransportationService>();
      final api = context.read<ApiClient>();
      final token = await api.readToken();
      _tracking = await transport.getLiveTracking(studentId: widget.studentId);

      final busLat = _tracking?.busLatitude;
      final busLng = _tracking?.busLongitude;
      if (busLat != null && busLng != null) {
        _busLocation = MapLineUtils.sanitize(LatLng(busLat, busLng));
      }

      _syncConnectionLine();

      // لا نؤخر فتح الخريطة على GPS ولي الأمر — نجلبه بالتوازي بعد العرض
      if (!mounted) return;
      setState(() {
        _loading = false;
        _mapGeneration++;
        _followBus = true;
      });

      unawaited(_refreshRoadRoute());

      if (token != null && _tracking != null) {
        await _signalR.connect(transport, token);
        await _signalR.joinTrip(_tracking!.tripId);
        _signalR.onBusLocationUpdated = ({
          required tripId,
          required latitude,
          required longitude,
          speedKmh,
          heading,
          status,
        }) {
          if (!mounted) return;
          final next = MapLineUtils.sanitize(LatLng(latitude, longitude));
          if (next == null) return;
          setState(() {
            _busLocation = next;
            _tracking = LiveTrackingData(
              tripId: _tracking!.tripId,
              tripStatus: status ?? _tracking!.tripStatus,
              tripType: _tracking!.tripType,
              busLatitude: next.latitude,
              busLongitude: next.longitude,
              busSpeedKmh: speedKmh,
              busHeading: heading,
              lastLocationAt: DateTime.now(),
              routeName: _tracking!.routeName,
              busNumber: _tracking!.busNumber,
              driverName: _tracking!.driverName,
              driverPhone: _tracking!.driverPhone,
              supervisorName: _tracking!.supervisorName,
              supervisorPhone: _tracking!.supervisorPhone,
              studentPickupLatitude: _tracking!.studentPickupLatitude,
              studentPickupLongitude: _tracking!.studentPickupLongitude,
              distanceRemainingKm: _tracking!.distanceRemainingKm,
              etaMinutes: _tracking!.etaMinutes,
              studentTripStatus: _tracking!.studentTripStatus,
              stops: _tracking!.stops,
            );
          });
          _syncConnectionLine();
          _maybeFollowBus(next);
          unawaited(_refreshRoadRoute());
        };
      }

      _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
        try {
          final latest = await transport.getLiveTracking(studentId: widget.studentId);
          if (!mounted) return;
          final nextBus = (latest.busLatitude != null && latest.busLongitude != null)
              ? MapLineUtils.sanitize(LatLng(latest.busLatitude!, latest.busLongitude!))
              : null;
          setState(() {
            _tracking = latest;
            if (nextBus != null) _busLocation = nextBus;
          });
          _syncConnectionLine();
          if (nextBus != null) _maybeFollowBus(nextBus);
          await _refreshRoadRoute();
        } catch (_) {}
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is NoActiveTripException
            ? e.toString()
            : e.toString().replaceFirst('Exception: ', '');
        _isNoActiveTrip = e is NoActiveTripException;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
      _isNoActiveTrip = false;
      _connectionLine = const [];
      _roadRoutePoints = const [];
      _liveDistanceText = null;
      _liveDurationText = null;
      _lastRouteOrigin = null;
      _mapReady = false;
      _followBus = true;
    });
    await _bootstrap();
  }

  Future<void> _refreshRoadRoute() async {
    final bus = MapLineUtils.sanitize(_busLocation);
    final target = _routeTarget;
    if (bus == null || target == null) return;

    _syncConnectionLine();

    final needsFetch = OsrmRouteService.shouldRefreshRoute(
      lastOrigin: _lastRouteOrigin,
      currentOrigin: bus,
    );
    if (!needsFetch || _requestingRoute) return;

    _requestingRoute = true;
    try {
      final result = await _osrm.fetchRoute(bus, target);
      if (!mounted) return;
      _lastRouteOrigin = bus;
      final points = (result?.points ?? [bus, target])
          .map(MapLineUtils.sanitize)
          .whereType<LatLng>()
          .toList(growable: false);
      setState(() {
        _roadRoutePoints = points.length >= 2 ? points : const [];
        if (result != null) {
          _liveDistanceText = result.distanceText;
          _liveDurationText =
              result.durationSeconds > 0 ? result.durationText : null;
        }
      });
    } finally {
      _requestingRoute = false;
    }
  }

  void _maybeFollowBus(LatLng bus) {
    if (!_followBus || !_mapReady) return;
    try {
      // نثبت زوم الشارع دائمًا أثناء المتابعة — مش نبعد عشان ولي الأمر
      _mapController.move(bus, _streetZoom);
    } catch (_) {}
  }

  void _focusOnBus() {
    final bus = MapLineUtils.sanitize(_busLocation) ?? _pickupLatLng;
    if (bus == null || !_mapReady) return;
    _followBus = true;
    try {
      _mapController.move(bus, _streetZoom);
    } catch (_) {}
  }

  void _onMapReady() {
    _mapReady = true;
    // تأخير بسيط بعد جاهزية الخريطة ثم زوم شارع على الباص
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        _focusOnBus();
      });
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (!mounted || !_followBus) return;
        _focusOnBus();
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _signalR.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الحافلة'),
        actions: [
          IconButton(
            tooltip: 'تركيز على الباص',
            onPressed: _focusOnBus,
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _TrackingEmptyState(
                  message: _error!,
                  isNoActiveTrip: _isNoActiveTrip,
                  onRetry: _retry,
                )
              : Column(
                  children: [
                    Expanded(
                      child: FlutterMap(
                        // جيل جديد فقط عند فتح/إعادة تحميل الشاشة — مش مع كل حركة باص
                        key: ValueKey('live-map-$_mapGeneration'),
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _mapCenter,
                          initialZoom: _streetZoom,
                          minZoom: 12,
                          maxZoom: 19,
                          onMapReady: _onMapReady,
                          onPositionChanged: (camera, hasGesture) {
                            if (hasGesture) {
                              // المستخدم حرّك الخريطة — نوقف المتابعة التلقائية
                              _followBus = false;
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            // OSM: أسماء الشوارع (عربي في مصر) تظهر بوضوح من زوم 16–18
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.alsakr.school.family',
                            maxNativeZoom: 19,
                            maxZoom: 19,
                            keepBuffer: 2,
                          ),
                          if (_roadRoutePoints.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _roadRoutePoints,
                                  color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                                  strokeWidth: 4,
                                ),
                              ],
                            ),
                          if (_connectionLine.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _connectionLine,
                                  color: const Color(0xFF1565C0),
                                  strokeWidth: 6,
                                  borderStrokeWidth: 2,
                                  borderColor: Colors.white,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              if (MapLineUtils.sanitize(_busLocation) != null)
                                Marker(
                                  point: MapLineUtils.sanitize(_busLocation)!,
                                  width: 52,
                                  height: 52,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.directions_bus_rounded,
                                    color: Colors.red,
                                    size: 44,
                                  ),
                                ),
                              if (_pickupLatLng != null)
                                Marker(
                                  point: _pickupLatLng!,
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.bottomCenter,
                                  child: const Icon(
                                    Icons.home_rounded,
                                    color: AppColors.accent,
                                    size: 32,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_tracking != null)
                      _InfoPanel(
                        tracking: _tracking!,
                        liveDistanceText: _liveDistanceText,
                        liveDurationText: _liveDurationText,
                        followBus: _followBus,
                        onFocusBus: _focusOnBus,
                      ),
                  ],
                ),
    );
  }
}

class _TrackingEmptyState extends StatelessWidget {
  const _TrackingEmptyState({
    required this.message,
    required this.isNoActiveTrip,
    required this.onRetry,
  });

  final String message;
  final bool isNoActiveTrip;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNoActiveTrip
                    ? Icons.directions_bus_filled_rounded
                    : Icons.error_outline_rounded,
                size: 44,
                color: isNoActiveTrip ? AppColors.primary : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isNoActiveTrip ? 'لا توجد رحلة نشطة' : 'تعذر تحميل التتبع',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              isNoActiveTrip
                  ? 'لم يبدأ السائق رحلة لهذا الطالب بعد.\nيمكنك المحاولة لاحقاً عند بدء الرحلة.'
                  : message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.tracking,
    required this.followBus,
    required this.onFocusBus,
    this.liveDistanceText,
    this.liveDurationText,
  });

  final LiveTrackingData tracking;
  final bool followBus;
  final VoidCallback onFocusBus;
  final String? liveDistanceText;
  final String? liveDurationText;

  @override
  Widget build(BuildContext context) {
    final distance = liveDistanceText ??
        (tracking.distanceRemainingKm != null
            ? '${tracking.distanceRemainingKm!.toStringAsFixed(1)} كم'
            : null);
    final eta = liveDurationText ??
        (tracking.etaMinutes != null ? '${tracking.etaMinutes} د' : null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${tracking.routeName} • ${tracking.busNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onFocusBus,
                icon: Icon(
                  followBus ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                  size: 18,
                ),
                label: Text(followBus ? 'متابعة الباص' : 'العودة للباص'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('الحالة', tracking.tripStatus),
              if (eta != null) _chip('الوصول', eta),
              if (distance != null) _chip('المسافة', distance),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.person_rounded, color: AppColors.primary),
              title: Text(
                tracking.driverName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('سائق • ${tracking.driverPhone}'),
            ),
          ),
          if (tracking.supervisorName != null)
            AppCard(
              child: ListTile(
                leading: const Icon(
                  Icons.supervisor_account_rounded,
                  color: AppColors.secondary,
                ),
                title: Text(
                  tracking.supervisorName!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('مشرف • ${tracking.supervisorPhone ?? ''}'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label: $value',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
}
