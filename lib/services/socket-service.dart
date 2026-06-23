import 'dart:developer';
import 'package:hosta/services/socket_controller.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  SocketService._internal();

  late IO.Socket socket;
SocketEventRouter? router;
  final Map<String, List<Function(dynamic)>> _listeners = {};
void setRouter(SocketEventRouter r) {
  router = r;
}
  void connect(String token) {
    socket = IO.io(
      "https://zorrowtek.in",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setAuth({"token": token})
          .build(),
    );

    socket.onConnect((_) {
      log("✅ Socket Connected");
    });

   socket.onAny((event, data) {
  log("📩 EVENT => $event");

 router?.handle(event, data);

  if (_listeners.containsKey(event)) {
    for (final callback in _listeners[event]!) {
      callback(data);
    }
  }
});

    socket.connect();
  }

  void addListener(
    List<String> events,
    Function(dynamic) callback,
  ) {
    for (final event in events) {
      _listeners.putIfAbsent(event, () => []);
      _listeners[event]!.add(callback);
    }
  }
}