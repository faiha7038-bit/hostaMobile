import 'dart:developer';

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  SocketService._internal();

  IO.Socket? socket;

  void connect(String userId) {
    if (socket?.connected == true) return;

    socket = IO.io(
      'https://www.zorrowtek.in',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
      },
    );

    socket!.connect();

    socket!.onConnect((_) {
      log('✅ Socket Connected');

      // Backend expects: join-room
      socket!.emit('join-room', userId);

      log('🏠 Joined room: $userId');
    });

    socket!.onDisconnect((_) {
      log('❌ Socket Disconnected');
    });

    socket!.onConnectError((error) {
      log('🚨 Connect Error: $error');
    });

    socket!.onError((error) {
      log('🚨 Socket Error: $error');
    });

    // Debug all incoming events
    socket!.onAny((event, data) {
      log('🔥 EVENT => $event');
      log('🔥 DATA => $data');
    });

    // Listen for backend notifications/events
    socket!.on('system_event', (data) {
      log('📢 SYSTEM EVENT => $data');

      // Example:
      // notificationProvider.refresh();
      // eventProvider.fetchEvents();
    });
  }

  void disconnect() {
    socket?.clearListeners();
    socket?.disconnect();
    socket?.dispose();
    socket = null;

    log('🛑 Socket Closed');
  }
}