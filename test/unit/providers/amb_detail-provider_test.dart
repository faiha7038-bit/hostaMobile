// test/unit/providers/ambulance_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/amb_detail-provider.dart';

void main() {
  // Each test nu mumpull oru fresh container
  late ProviderContainer container;
  late AmbulanceNotifier notifier;

  setUp(() {
    // Fresh Riverpod container create cheyyuka
    container = ProviderContainer();
    notifier = container.read(ambulanceProvider.notifier);
  });

  tearDown(() {
    // Test kazhinju container dispose cheyyuka
    container.dispose();
  });

  group('AmbulanceProvider Tests', () {
    
    test('Initial state should be available (isAvailable = true)', () {
      // Read state from provider
      final state = container.read(ambulanceProvider);
      
      // Verify initial value
      expect(state.isAvailable, true);
    });

    test('toggleAvailability should set isAvailable to false', () {
      // Act: Call the method
      notifier.toggleAvailability(false);
      
      // Assert: State update aayo?
      final state = container.read(ambulanceProvider);
      expect(state.isAvailable, false);
    });

    test('toggleAvailability should set isAvailable to true', () {
      // First set to false
      notifier.toggleAvailability(false);
      expect(container.read(ambulanceProvider).isAvailable, false);
      
      // Then set to true
      notifier.toggleAvailability(true);
      expect(container.read(ambulanceProvider).isAvailable, true);
    });

    test('Multiple toggles work correctly', () {
      // Toggle multiple times
      notifier.toggleAvailability(false);
      expect(container.read(ambulanceProvider).isAvailable, false);
      
      notifier.toggleAvailability(true);
      expect(container.read(ambulanceProvider).isAvailable, true);
      
      notifier.toggleAvailability(false);
      expect(container.read(ambulanceProvider).isAvailable, false);
    });

    test('copyWith should preserve other properties', () {
      final state = AmbulanceState(isAvailable: true);
      final newState = state.copyWith(isAvailable: false);
      
      expect(newState.isAvailable, false);
      // Ippo vere properties illa, but future il add aakumbol useful aakum
    });
  });
}