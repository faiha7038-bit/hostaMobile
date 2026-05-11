// test/widget/screens/ambulance_details_test.dart - COMPLETE VERSION
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosta/presentation/screens/ambulance/ambulance_details.dart';

void main() {
  group('AmbulanceDetailsPage Widget Tests', () {
    
    testWidgets('TC01: Screen loads without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.byType(AmbulanceDetailsPage), findsOneWidget);
    });

    testWidgets('TC02: AppBar title is "Ambulance Details"', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.text('Ambulance Details'), findsOneWidget);
    });

    testWidgets('TC03: Vehicle number is displayed', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.text('KL-11-AB-1234'), findsOneWidget);
    });

    testWidgets('TC04: Vehicle type shows "Type: ICU"', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.text('Type: ICU'), findsOneWidget);
    });

    testWidgets('TC05: Driver name shows "Driver: Rahman"', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.text('Driver: Rahman'), findsOneWidget);
    });

    testWidgets('TC06: Phone number shows', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.text('Phone: 9876543210'), findsOneWidget);
    });

    testWidgets('TC07: Location shows "Location: Calicut"', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.text('Location: Calicut'), findsOneWidget);
    });

    testWidgets('TC08: Facilities section exists', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.text('Facilities'), findsOneWidget);
    });

    testWidgets('TC09: Facility chips are displayed', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.text('Oxygen'), findsOneWidget);
      expect(find.text('Ventilator'), findsOneWidget);
      expect(find.text('Stretcher'), findsOneWidget);
    });

    testWidgets('TC10: Back button exists', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('TC11: Edit icon exists', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('TC12: Delete icon exists', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.byIcon(Icons.delete_forever_rounded), findsOneWidget);
    });

    testWidgets('TC13: Availability status shows "Available" initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.text('Available'), findsOneWidget);
    });

    testWidgets('TC14: Switch widget exists', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('TC15: Toggle switch changes availability status', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AmbulanceDetailsPage(),
          ),
        ),
      );
      
      await tester.pump();
      
      // Initially "Available"
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Not Available'), findsNothing);
      
      // Tap the switch
      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pump();
      
      // After toggle, should show "Not Available"
      expect(find.text('Not Available'), findsOneWidget);
      expect(find.text('Available'), findsNothing);
    });
  });
}