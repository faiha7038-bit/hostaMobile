// test/widget/screens/notification_test.dart
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hosta/presentation/screens/notification/notifications.dart';

void main() {
  // Setup Firebase mocks
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
  });

  group('Notification Screen - Login State Tests', () {
    
    testWidgets('TC01: Show login prompt when user NOT logged in', (tester) async {
      // No user
      SharedPreferences.setMockInitialValues({});
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Notifications(),
        ),
      );
      
      await tester.pump();
      
      expect(find.text('Please login to view notifications'), findsOneWidget);
      expect(find.byIcon(Icons.person_off), findsOneWidget);
    });

    testWidgets('TC02: AppBar title is "Notifications"', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userId': 'test_user_123',
      });
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Notifications(),
        ),
      );
      
      await tester.pump();
      
      expect(find.text('Notifications'), findsOneWidget);
    });
  });

  group('Notification Screen - Loading State Tests', () {
    
    // TC03: Commented out - requires real API mock
    // testWidgets('TC03: Loading indicator shows while fetching data', (tester) async {
    //   SharedPreferences.setMockInitialValues({
    //     'userId': 'test_user_123',
    //   });
    //   
    //   await tester.pumpWidget(
    //     const MaterialApp(
    //       home: Notifications(),
    //     ),
    //   );
    //   
    //   await tester.pump();
    //   
    //   expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // });
  });

  group('Notification Screen - UI Elements Tests', () {
    
    // TC04: Commented out - requires real API data
    // testWidgets('TC04: Filter chips section exists', (tester) async {
    //   SharedPreferences.setMockInitialValues({
    //     'userId': 'test_user_123',
    //   });
    //   
    //   await tester.pumpWidget(
    //     const MaterialApp(
    //       home: Notifications(),
    //     ),
    //   );
    //   
    //   await tester.pump();
    //   
    //   expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    //   expect(find.text('Filter'), findsOneWidget);
    // });
    
    testWidgets('TC05: Background color is correct', (tester) async {
      SharedPreferences.setMockInitialValues({
        'userId': 'test_user_123',
      });
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Notifications(),
        ),
      );
      
      await tester.pump();
      
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFECFDF5));
    });
  });
}