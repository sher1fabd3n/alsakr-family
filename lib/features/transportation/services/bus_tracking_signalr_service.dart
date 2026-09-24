import 'package:signalr_netcore/signalr_client.dart';

import 'transportation_service.dart';

typedef BusLocationCallback = void Function({
  required int tripId,
  required double latitude,
  required double longitude,
  double? speedKmh,
  double? heading,
  String? status,
});

class BusTrackingSignalRService {
  HubConnection? _connection;
  BusLocationCallback? onBusLocationUpdated;
  void Function(Map<String, dynamic> payload)? onTripStatusUpdated;
  void Function(Map<String, dynamic> payload)? onOccupancyUpdated;
  void Function(Map<String, dynamic> payload)? onEmergencyTriggered;

  Future<void> connect(TransportationService transport, String token) async {
    await disconnect();
    _connection = HubConnectionBuilder()
        .withUrl(
          transport.trackingHubUrl(token),
          options: HttpConnectionOptions(
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
          ),
        )
        .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000, 30000])
        .build();

    _connection!.onreconnecting(({error}) {});
    _connection!.onreconnected(({connectionId}) async {
      // Caller should re-join trip group after reconnect.
    });

    _connection!.on('BusLocationUpdated', (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      if (raw is! Map) return;
      final data = Map<String, dynamic>.from(raw);
      onBusLocationUpdated?.call(
        tripId: (data['tripId'] as num).toInt(),
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
        speedKmh: (data['speedKmh'] as num?)?.toDouble(),
        heading: (data['heading'] as num?)?.toDouble(),
        status: data['status'] as String?,
      );
    });

    _connection!.on('TripStatusUpdated', (args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map<String, dynamic>) {
        onTripStatusUpdated?.call(data);
      }
    });

    _connection!.on('OccupancyUpdated', (args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map<String, dynamic>) {
        onOccupancyUpdated?.call(data);
      }
    });

    _connection!.on('EmergencyTriggered', (args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map<String, dynamic>) {
        onEmergencyTriggered?.call(data);
      }
    });

    await _connection!.start();
  }

  Future<void> joinTrip(int tripId) async {
    await _connection?.invoke('JoinTrip', args: [tripId]);
  }

  Future<void> joinBus(int busId) async {
    await _connection?.invoke('JoinBus', args: [busId]);
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
    }
  }
}
