import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  SocketService._internal();

  late IO.Socket socket;
// SocketEventRouter? router;
  final Map<String, List<Function(dynamic)>> _listeners = {};
   String? _currentUserId;
// void setRouter(SocketEventRouter r) {
//   router = r;
// }
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

      // ✅ Join user room if userId is set
       if (_currentUserId != null) {
        _joinUserRoom(_currentUserId!);
      }
    });

   socket.onAny((event, data) {
  log("📩 EVENT => $event");

//  router?.handle(event, data);

  if (_listeners.containsKey(event)) {
    for (final callback in _listeners[event]!) {
      callback(data);
    }
  }
});

    socket.connect();
  }
 // ✅ New method to join user room
  void joinUserRoom(String userId) {
    _currentUserId = userId;
    if (socket.connected) {
      _joinUserRoom(userId);
    }
  }
   void _joinUserRoom(String userId) {
    socket.emit('joinUserRoom', userId);
    socket.emit('userOnline', userId);
    log("✅ Joined user room: $userId");
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
  void removeListener(String event, Function(dynamic) callback) {
  if (_listeners.containsKey(event)) {
    _listeners[event]!.remove(callback);
    if (_listeners[event]!.isEmpty) {
      _listeners.remove(event);
    }
  }
}
}