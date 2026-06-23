import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/ambulance-provider.dart';
import 'package:hosta/providers/booking_provider.dart';
import 'package:hosta/providers/specialities-provider.dart';

class SocketEventRouter {
  final Ref ref;

  SocketEventRouter(this.ref);

  void handle(String event, dynamic data) {

    // ───────── BOOKINGS ─────────
    if (_bookingEvents.contains(event)) {
      ref.read(bookingStateProvider.notifier).fetchBookings();
      return;
    }

    // ───────── SPECIALITY ─────────
    if (_specialityEvents.contains(event)) {
     ref.read(specialityRefreshProvider.notifier).state++;
      return;
    }

    // ───────── AMBULANCE ─────────
    if (_ambulanceEvents.contains(event)) {
      ref.read(ambulanceListProvider.notifier).fetchAmbulances();
      return;
    }

    // ───────── DEFAULT ─────────
    return;
  }

  // 🔥 EVENT GROUPS
  static const _bookingEvents = {
    'BOOKING_REGISTERED',
    'BOOKING_UPDATED',
    'BOOKING_CANCELLED',
    'BOOKING_ACCEPTED',
    'BOOKING_COMPLETED',
  };

  static const _specialityEvents = {
    'SPECIALITY_REGISTERED',
    'SPECIALITY_UPDATED',
    'SPECIALITY_DELETED',
  };

  static const _ambulanceEvents = {
    'AMBULANCE_REGISTERED',
    'AMBULANCE_UPDATED',
    'AMBULANCE_DELETED',
  };
}