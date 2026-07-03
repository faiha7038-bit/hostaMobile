import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  SocketService._internal();

  IO.Socket? socket;
  final Map<String, List<Function(dynamic)>> _listeners = {};
   String? _currentUserId;

 void connect(String token) {
 

  if (socket != null) {
    if (socket!.connected) {
   
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
 

  if (_currentUserId != null) {
    _joinUserRoom(_currentUserId!);
  }
});

socket!.onDisconnect((reason) {
 
});

socket!.onConnectError((err) {
 
});

socket!.onReconnect((_) {

});

socket!.onReconnectAttempt((attempt) {
  
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