import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/services/socket_controller.dart';

final socketRouterProvider = Provider<SocketEventRouter>((ref) {
  return SocketEventRouter(ref);
});