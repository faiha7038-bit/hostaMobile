import 'package:flutter_riverpod/flutter_riverpod.dart';

class AmbulanceState {
  final bool isAvailable;

  AmbulanceState({required this.isAvailable});

  AmbulanceState copyWith({bool? isAvailable}) {
    return AmbulanceState(
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class AmbulanceNotifier extends StateNotifier<AmbulanceState> {
  AmbulanceNotifier() : super(AmbulanceState(isAvailable: true));

  void toggleAvailability(bool value) {
    state = state.copyWith(isAvailable: value);
  }
}

final ambulanceProvider =
    StateNotifierProvider<AmbulanceNotifier, AmbulanceState>(
  (ref) => AmbulanceNotifier(),
);