import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  SocketService._internal();

  IO.Socket? socket;
  final Map<String, List<Function(dynamic)>> _listeners = {};
   String? _currentUserId;

 void connect(String token) {
  log("connect() CALLED");

  if (socket != null) {
    if (socket!.connected) {
      log("✅ Socket already connected");
      return;
    }

    socket!.dispose();
    socket = null;
  }

  socket = IO.io(
    "https://zorrowtek.in",
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableReconnection()
        .setReconnectionAttempts(999999)
        .setReconnectionDelay(2000)
        .setAuth({"token": token})
        .build(),
  );

   socket!.onConnect((_) {
  log("✅ Socket Connected");

  if (_currentUserId != null) {
    _joinUserRoom(_currentUserId!);
  }
});

socket!.onDisconnect((reason) {
  log("❌ Socket Disconnected: $reason");
});

socket!.onConnectError((err) {
  log("❌ Connect Error: $err");
});

socket!.onReconnect((_) {
  log("🔄 Reconnected");
});

socket!.onReconnectAttempt((attempt) {
  log("🔄 Reconnect attempt: $attempt");
});

// Direct events
socket!.onAny((event, data) {
  final listeners = _listeners[event];
  if (listeners != null) {
    for (final callback in listeners) {
      callback(data);
    }
  }
});

// System events (Booking, Prescription, etc.)
socket!.on("system_event", (payload) {
  if (payload == null) return;

  final message = payload["message"]?.toString() ?? "";
  final match = RegExp(r'\[(.*?)\]').firstMatch(message);

  if (match == null) return;

  final event = match.group(1)!;

  log("System Event => $event");

  final listeners = _listeners[event];
  if (listeners != null) {
    for (final callback in listeners) {
      callback(payload["data"]);
    }
  }
});

    socket!.connect();
 
  }
  
 // ✅ New method to join user room
 void joinUserRoom(String userId) {
  _currentUserId = userId;

  if (socket != null && socket!.connected) {
    _joinUserRoom(userId);
  }
}
   void _joinUserRoom(String userId) {
    socket!.emit('joinUserRoom', userId);
    socket!.emit('userOnline', userId);
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