import 'package:signalr_netcore/signalr_client.dart';

import '../models/communication_models.dart';
import 'communication_service.dart';

class SignalRChatService {
  HubConnection? _connection;
  void Function(ChatMessageItem message)? onMessage;
  void Function()? onReconnecting;

  Future<void> connect(CommunicationService communication, String token) async {
    await disconnect();
    _connection = HubConnectionBuilder()
        .withUrl(
          communication.hubUrl(token),
          options: HttpConnectionOptions(
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveMessage', (args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map<String, dynamic>) {
        onMessage?.call(ChatMessageItem.fromJson(data));
      }
    });

    _connection!.onreconnecting(({error}) => onReconnecting?.call());
    await _connection!.start();
  }

  Future<void> joinConversation(int conversationId) async {
    await _connection?.invoke('JoinConversation', args: [conversationId]);
  }

  Future<void> sendTyping(int conversationId) async {
    await _connection?.invoke('SendTyping', args: [conversationId]);
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
    }
  }
}
