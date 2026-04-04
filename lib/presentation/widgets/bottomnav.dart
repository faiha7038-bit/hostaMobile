
// import 'package:flutter/material.dart';
// import 'package:curved_navigation_bar/curved_navigation_bar.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_app_badger/flutter_app_badger.dart';
// import 'package:hosta/common/top_snackbar.dart';
// import 'package:hosta/components/about.dart';
// import 'package:hosta/components/contact.dart';
// import 'package:hosta/components/privacy.dart';
// import 'package:hosta/components/profile.dart';
// import 'package:hosta/firebase_msg.dart';
// import 'package:hosta/pages/profile.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'home.dart';
// import 'booking.dart';
// import 'notifications.dart';
// import '../services/api_service.dart';

// class Bottomnav extends ConsumerStatefulWidget {
//   const Bottomnav({super.key});

//   @override
//   ConsumerState<Bottomnav> createState() => _BottomNavState();
// }

// class _BottomNavState extends ConsumerState<Bottomnav> {
//   int currentTabIndex = 0;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   int notificationCount = 0;
//   Map<String, dynamic> userData = {};
//   bool isLoadingUser = true;
//   String? userId;
//   IO.Socket? socket;
//   OverlayEntry? _overlayEntry;
  
//   // PageController for swipe functionality
//   late PageController _pageController;
  
//   final FirebaseMsg _firebaseMsg = FirebaseMsg();
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;

//   final List<GlobalKey> _pageKeys = [
//     GlobalKey(),
//     GlobalKey(),
//     GlobalKey(),
//     GlobalKey(), // Added for profile page
//   ];

//   late List<Widget> pages;

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: currentTabIndex);
//     _initializePages();
//     _loadUserId();
//     _checkBadgeSupport();
//     _initializeFCM();
//   }

//   void _initializePages() {
//     pages = [
//       const Home(key: ValueKey('home_page')),
//       Booking(key: _pageKeys[1]),
//       const Notifications(key: ValueKey('notifications_page')),
//       ProfilePage(key: _pageKeys[3]), // Added profile page to pages list
//     ];
//   }

//   Future<void> _initializeFCM() async {
//     try {
//       print('🔍 DEBUG: Initializing FCM in BottomNav...');
//       await _firebaseMsg.initFCM();
//       _setupFCMListeners();
//       await _sendFCMTokenToBackend();
//       print('✅ DEBUG: FCM initialized successfully in BottomNav');
//     } catch (e) {
//       print('❌ ERROR initializing FCM in BottomNav: $e');
//     }
//   }

//   Future<void> _sendFCMTokenToBackend() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final fcmToken = prefs.getString('fcm_token');
//       final userId = prefs.getString('userId');
      
//       if (fcmToken != null && userId != null && userId.isNotEmpty) {
//         print('🚀 Sending FCM token to backend server...');
//         print('🪙 FCM Token: $fcmToken');
//         print('👤 User ID: $userId');
        
//         // TODO: Send to your backend API
//         // await ApiService().registerFCMToken(userId, fcmToken);
        
//         print('✅ FCM token sent to backend successfully');
//       } else {
//         print('⚠️ Cannot send FCM token: User ID or Token missing');
//       }
//     } catch (e) {
//       print('❌ Error sending FCM token to backend: $e');
//     }
//   }

//   void _setupFCMListeners() {
//     print('🔍 DEBUG: Setting up FCM listeners...');
    
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print('📱 FCM Foreground message received in BottomNav');
//       _handleIncomingNotification(message, isFromFCM: true);
//     });

//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print('📱 FCM App opened from notification in BottomNav');
//       _handleNotificationTap(message);
//     });

//     _handleInitialNotification();

//     _fcm.onTokenRefresh.listen((newToken) {
//       print('🔄 FCM Token refreshed in BottomNav: $newToken');
//       _sendRefreshedTokenToBackend(newToken);
//     });

//     print('✅ DEBUG: FCM listeners setup completed');
//   }

//   Future<void> _sendRefreshedTokenToBackend(String newToken) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('userId');
      
//       if (userId != null && userId.isNotEmpty) {
//         print('🔄 Sending refreshed FCM token to backend...');
//         print('🪙 New FCM Token: $newToken');
        
//         // TODO: Send refreshed token to your backend API
//         // await ApiService().updateFCMToken(userId, newToken);
        
//         print('✅ Refreshed FCM token sent to backend successfully');
//       }
//     } catch (e) {
//       print('❌ Error sending refreshed FCM token to backend: $e');
//     }
//   }

//   Future<void> _handleInitialNotification() async {
//     try {
//       RemoteMessage? initialMessage = await _fcm.getInitialMessage();
//       if (initialMessage != null) {
//         print('📱 FCM Initial message found: ${initialMessage.messageId}');
//         _handleNotificationTap(initialMessage);
//       } else {
//         print('📱 No initial FCM message found');
//       }
//     } catch (e) {
//       print('❌ ERROR handling initial notification: $e');
//     }
//   }

//   void _handleIncomingNotification(RemoteMessage message, {bool isFromFCM = false}) {
//     print('📱 Handling incoming notification in BottomNav');
    
//     final notification = message.notification;
//     final data = message.data;

//     String title = 'New Notification';
//     String body = 'You have a new message';

//     if (notification != null) {
//       title = notification.title ?? title;
//       body = notification.body ?? body;
//     } else if (data.isNotEmpty) {
//       title = data['title'] ?? data['notificationTitle'] ?? title;
//       body = data['body'] ?? data['notificationBody'] ?? data['message'] ?? body;
//     }

//     _showCustomPushNotification(title, body);
//     _incrementNotificationCount();
//     _updateAppIconBadge();

//     print('📱 Notification handled - Title: $title, Body: $body, From FCM: $isFromFCM');
    
//     _refetchNotifications();
//   }

//   void _handleNotificationTap(RemoteMessage message) {
//     print('📱 Notification tapped, navigating to notifications page');
    
//     if (mounted) {
//       _navigateToTab(2);
//     }
    
//     _refetchNotifications();
//   }

//   void _navigateToTab(int index) {
//     if (index >= 0 && index < pages.length) {
//       setState(() {
//         currentTabIndex = index;
//       });
      
//       _pageController.animateToPage(
//         index,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
      
//       if (index == 2) {
//         _markNotificationsAsRead();
//       }
//     }
//   }

//   Future<void> _checkBadgeSupport() async {
//     try {
//       bool isSupported = await FlutterAppBadger.isAppBadgeSupported();
//       print('🛎️ App badge supported: $isSupported');
//     } catch (e) {
//       print("❌ Error checking badge support: $e");
//     }
//   }

//   Future<void> _updateAppIconBadge() async {
//     try {
//       if (notificationCount > 0) {
//         await FlutterAppBadger.updateBadgeCount(notificationCount);
//         print('🛎️ Updated app badge count: $notificationCount');
//       } else {
//         await FlutterAppBadger.removeBadge();
//         print('🛎️ Removed app badge');
//       }
//     } catch (e) {
//       print("❌ Error updating app icon badge: $e");
//     }
//   }

//   Future<void> _loadUserId() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final storedUserId = prefs.getString('userId');
      
//       if (mounted) {
//         setState(() {
//           userId = storedUserId;
//         });
//       }
      
//       print('👤 User ID loaded: $userId');
      
//       if (userId != null && userId!.isNotEmpty) {
//         await _loadUserData();
//         await _loadNotificationCountFromStorage();
//         _setupSocketListener();
//       } else {
//         setState(() => isLoadingUser = false);
//       }
      
//     } catch (e) {
//       print("❌ Error loading user ID: $e");
//       setState(() => isLoadingUser = false);
//     }
//   }

//   Future<void> _loadNotificationCountFromStorage() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final savedCount = prefs.getInt('notification_count') ?? 0;
//       if (mounted) {
//         setState(() {
//           notificationCount = savedCount;
//         });
//         _updateAppIconBadge();
//       }
      
//       print('📊 Loaded notification count from storage: $savedCount');
//       await _loadNotificationCountFromAPI();
//     } catch (e) {
//       print("❌ Error loading notification count from storage: $e");
//       await _loadNotificationCountFromAPI();
//     }
//   }

//   Future<void> _saveNotificationCountToStorage(int count) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setInt('notification_count', count);
//       print('💾 Saved notification count to storage: $count');
//     } catch (e) {
//       print("❌ Error saving notification count to storage: $e");
//     }
//   }

//   Future<void> _loadUserData() async {
//     if (userId == null || userId!.isEmpty) {
//       setState(() => isLoadingUser = false);
//       return;
//     }

//     try {
//       setState(() => isLoadingUser = true);
//       final response = await ApiService().getAUser(userId!);
      
//       if (mounted) {
//         setState(() {
//           userData = response.data['data'] ?? {};
//         });
//       }
//       print('👤 User data loaded successfully');
//     } catch (e) {
//       print("❌ Error loading user data: $e");
//       showTopSnackBar(context, "Error loading user data", isError: true);
//     } finally {
//       if (mounted) {
//         setState(() => isLoadingUser = false);
//       }
//     }
//   }

//   Future<void> _loadNotificationCountFromAPI() async {
//     if (userId == null || userId!.isEmpty) {
//       return;
//     }

//     try {
//       final response = await ApiService().getAllNotificationUnRead(userId!);
      
//       List<dynamic> notifications = [];
      
//       if (response.data is List) {
//         notifications = response.data as List<dynamic>;
//       } else if (response.data?['notifications'] is List) {
//         notifications = response.data!['notifications'] as List<dynamic>;
//       } else if (response.data?['data'] is List) {
//         notifications = response.data!['data'] as List<dynamic>;
//       }
            
//       final unreadCount = notifications.where((notification) {
//         final userIsRead = notification['userIsRead'] ?? true;
//         final isRead = notification['isRead'] ?? true;
        
//         return userIsRead == false || isRead == false;
//       }).length;
            
//       if (mounted) {
//         setState(() {
//           notificationCount = unreadCount;
//         });
//         await _saveNotificationCountToStorage(unreadCount);
//         _updateAppIconBadge();
//       }
      
//       print('📊 Loaded notification count from API: $unreadCount');
//     } catch (e) {
//       print("❌ Error loading notifications from API: $e");
//       if (mounted) {
//         setState(() {
//           notificationCount = 0;
//         });
//         _updateAppIconBadge();
//       }
//     }
//   }

//   void _setupSocketListener() {
//     try {
//       const String serverUrl = 'https://www.zorrowtek.in';
      
//       socket = IO.io(serverUrl, <String, dynamic>{
//         'transports': ['websocket', 'polling'],
//         'autoConnect': true,
//         'reconnection': true,
//         'reconnectionAttempts': 5,
//         'reconnectionDelay': 1000,
//       });

//       socket!.on('connect', (_) {
//         print("✅ Connected to server via Socket.IO");
        
//         _sendFCMTokenToSocket();
        
//         if (userId != null && userId!.isNotEmpty) {
//           socket!.emit('joinUserRoom', {'userId': userId});
//           print("🚪 Joined user room: $userId");
//         }
//       });

//       socket!.on('disconnect', (_) {
//         print("🔌 Disconnected from server");
//       });

//       socket!.on('error', (error) {
//         print('⚠️ Socket error: $error');
//       });

//       socket!.on('pushNotificationPhone', (data) {
//         print('📡 Socket notification received: $data');
        
//         final notificationUserId = data['userId']?.toString();
//         final message = data['message']?.toString() ?? 'New notification';
//         final title = data['title']?.toString() ?? 'New Notification';
        
//         if (notificationUserId == userId) {
//           print('📱 Processing socket notification for current user');
          
//           final remoteMessage = RemoteMessage(
//             notification: RemoteNotification(
//               title: title,
//               body: message,
//             ),
//             data: data is Map<String, dynamic> ? data : {'fromSocket': 'true'},
//           );
          
//           _handleIncomingNotification(remoteMessage, isFromFCM: false);
//         }
//       });

//       socket!.on('profile', (data) {
//         print('📡 Profile update socket event received: $data');
        
//         final profileUserId = data['userId']?.toString();
        
//         if (profileUserId == userId) {
//           print('🔄 Processing profile update for current user');
//           _refreshUserData();
//         }
//       });

//       socket!.connect();
//       print('🔌 Socket.IO connection initiated');

//     } catch (e) {
//       print('❌ Error setting up socket: $e');
//     }
//   }

//   Future<void> _refreshUserData() async {
//     if (userId == null || userId!.isEmpty) {
//       return;
//     }

//     try {
//       print('🔄 Refreshing user data after profile update...');
      
//       final response = await ApiService().getAUser(userId!);
      
//       if (mounted) {
//         setState(() {
//           userData = response.data['data'] ?? {};
//         });
//       }
      
//       print('✅ User data refreshed successfully after profile update');
      
//     } catch (e) {
//       print('❌ Error refreshing user data: $e');
//       if (mounted) {
//         showTopSnackBar(context, "Error refreshing profile data", isError: true);
//       }
//     }
//   }

//   Future<void> _sendFCMTokenToSocket() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final fcmToken = prefs.getString('fcm_token');
      
//       if (fcmToken != null && socket != null && socket!.connected) {
//         print('📡 Sending FCM token to socket...');
//         socket!.emit('registerFCMToken', {
//           'userId': userId,
//           'fcmToken': fcmToken,
//         });
//         print('✅ FCM token sent to socket successfully');
//       }
//     } catch (e) {
//       print('❌ Error sending FCM token to socket: $e');
//     }
//   }

//   Future<void> _refetchNotifications() async {
//     try {
//       print('🔄 Refetching notifications from API...');
//       await _loadNotificationCountFromAPI();
//     } catch (e) {
//       print("❌ Error refetching notifications: $e");
//     }
//   }

//   void _incrementNotificationCount() {
//     if (mounted) {
//       setState(() {
//         notificationCount++;
//         _saveNotificationCountToStorage(notificationCount);
//       });
//       _updateAppIconBadge(); 
//       print('➕ Incremented notification count: $notificationCount');
//     }
//   }

//   void _showCustomPushNotification(String title, String message) {
//     _removeOverlay();

//     _overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         top: MediaQuery.of(context).padding.top + 10,
//         left: 10,
//         right: 10,
//         child: Material(
//           color: Colors.transparent,
//           child: GestureDetector(
//             onTap: () {
//               _removeOverlay();
//               if (mounted) {
//                 _navigateToTab(2);
//               }
//             },
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.green,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 10,
//                     spreadRadius: 2,
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: const Icon(
//                       Icons.notifications_active,
//                       color: Colors.green,
//                       size: 20,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           title,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           message,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close, color: Colors.white, size: 18),
//                     onPressed: _removeOverlay,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );

//     Overlay.of(context).insert(_overlayEntry!);

//     Future.delayed(const Duration(seconds: 5), _removeOverlay);
    
//     print('📱 Custom push notification shown: $title');
//   }

//   void _removeOverlay() {
//     if (_overlayEntry != null) {
//       _overlayEntry!.remove();
//       _overlayEntry = null;
//       print('📱 Custom notification overlay removed');
//     }
//   }

//   void _markNotificationsAsRead() {
//     if (mounted) {
//       setState(() {
//         notificationCount = 0;
//         _saveNotificationCountToStorage(0);
//       });
//       _updateAppIconBadge();       
//       print('📱 Notifications marked as read');
//     }
//   }

//   @override
//   void dispose() {
//     _removeOverlay();
//     _pageController.dispose();
//     socket?.disconnect();
//     socket?.close();
//     print('🔄 BottomNav disposed');
//     super.dispose();
//   }

//   Widget _buildNotificationWithBadge() {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Icon(
//           currentTabIndex == 2 ? Icons.notifications : Icons.notifications_outlined,
//           color: Colors.white,
//           size: 32.0,
//         ),
//         if (notificationCount > 0)
//           Positioned(
//             right: -5,
//             top: -8,
//             child: Container(
//               padding: const EdgeInsets.all(3),
//               decoration: BoxDecoration(
//                 color: Colors.red,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               constraints: const BoxConstraints(
//                 minWidth: 20,
//                 minHeight: 20,
//               ),
//               child: Text(
//                 notificationCount > 99 ? '99+' : notificationCount.toString(),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 11,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildNavIcon(IconData icon, IconData outlinedIcon, int index) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 8.0),
//       child: Icon(
//         currentTabIndex == index ? icon : outlinedIcon,
//         color: Colors.white,
//         size: 32.0,
//       ),
//     );
//   }

//   // Helper method to safely get profile image URL from your data structure
//   String? _getProfileImageUrl() {
//     final picture = userData['picture'];
    
//     if (picture == null) return null;
    
//     // Handle your specific image structure: { imageUrl: { type: String }, public_id: { type: String } }
//     if (picture is Map) {
//       // Check if imageUrl exists in the picture map
//       if (picture['imageUrl'] != null) {
//         final imageUrl = picture['imageUrl'];
//         // Handle if imageUrl is a Map with type field or direct string
//         if (imageUrl is Map && imageUrl['type'] != null) {
//           return imageUrl['type'] as String?;
//         } else if (imageUrl is String) {
//           return imageUrl;
//         }
//       }
      
//       // Also check if picture itself has a url field (fallback)
//       if (picture['url'] is String) {
//         return picture['url'] as String;
//       }
//     }
    
//     // If picture is directly a string (fallback)
//     if (picture is String && picture.isNotEmpty) {
//       return picture;
//     }
    
//     return null;
//   }

//   // Removed _buildSidebar method completely
//   // Now profile icon directly opens ProfilePage

//   @override
//   Widget build(BuildContext context) {
//     print("🎯 Current notification count: $notificationCount");
//     print("👤 User ID: $userId");
//     print("📱 Current tab index: $currentTabIndex");
    
//     return Scaffold(
//       key: _scaffoldKey,
//       // Removed endDrawer completely
//       body: PageView(
//         controller: _pageController,
//         onPageChanged: (index) {
//           setState(() {
//             currentTabIndex = index;
//             if (index == 2) {
//               print("📢 Marking notifications as read from swipe");
//               _markNotificationsAsRead();
//             }
//           });
//         },
//         children: pages,
//       ),
//       bottomNavigationBar: CurvedNavigationBar(
//         height: 68,
//         backgroundColor: const Color(0xFFECFDF5),
//         color: const Color(0xFF28A745),
//         animationDuration: const Duration(milliseconds: 300),
//         items: <Widget>[
//           _buildNavIcon(Icons.home, Icons.home_outlined, 0),
//           _buildNavIcon(Icons.calendar_today, Icons.calendar_today_outlined, 1),
//           _buildNotificationWithBadge(),
//           _buildNavIcon(Icons.person, Icons.person_outline, 3),
//         ],
//         onTap: (index) {
//           // Profile icon now directly navigates to profile page (index 3)
//           _navigateToTab(index);
//         },
//         index: currentTabIndex,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_app_badger_plus/flutter_app_badger_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/presentation/screens/about/about.dart';
import 'package:hosta/presentation/screens/contact/contact.dart';
import 'package:hosta/presentation/screens/privacy/privacy.dart';
import 'package:hosta/presentation/screens/profile-edit/profile.dart';
import 'package:hosta/firebase_msg.dart';
import 'package:hosta/presentation/screens/profile_show/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../screens/home/home.dart';
import '../screens/booking/booking.dart';
import '../screens/notification/notifications.dart';
import '../../services/api_service.dart';

class Bottomnav extends ConsumerStatefulWidget {
  const Bottomnav({super.key});

  @override
  ConsumerState<Bottomnav> createState() => _BottomNavState();
}

class _BottomNavState extends ConsumerState<Bottomnav> {
  int currentTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int notificationCount = 0;
  Map<String, dynamic> userData = {};
  bool isLoadingUser = true;
  String? userId;
  IO.Socket? socket;
  OverlayEntry? _overlayEntry;
  
  // PageController for swipe functionality
  late PageController _pageController;
  
  final FirebaseMsg _firebaseMsg = FirebaseMsg();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  final List<GlobalKey> _pageKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(), // Added for profile page
  ];

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentTabIndex);
    _initializePages();
    _loadUserId();
    _checkBadgeSupport();
    _initializeFCM();
  }

  void _initializePages() {
    pages = [
      const Home(key: ValueKey('home_page')),
      Booking(key: _pageKeys[1]),
      const Notifications(key: ValueKey('notifications_page')),
      ProfilePage(key: _pageKeys[3]), // Added profile page to pages list
    ];
  }

  Future<void> _initializeFCM() async {
    try {
      print('🔍 DEBUG: Initializing FCM in BottomNav...');
      await _firebaseMsg.initFCM();
      _setupFCMListeners();
      await _sendFCMTokenToBackend();
      print('✅ DEBUG: FCM initialized successfully in BottomNav');
    } catch (e) {
      print('❌ ERROR initializing FCM in BottomNav: $e');
    }
  }

  Future<void> _sendFCMTokenToBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');
      final userId = prefs.getString('userId');
      
      if (fcmToken != null && userId != null && userId.isNotEmpty) {
        print('🚀 Sending FCM token to backend server...');
        print('🪙 FCM Token: $fcmToken');
        print('👤 User ID: $userId');
        
        // TODO: Send to your backend API
        // await ApiService().registerFCMToken(userId, fcmToken);
        
        print('✅ FCM token sent to backend successfully');
      } else {
        print('⚠️ Cannot send FCM token: User ID or Token missing');
      }
    } catch (e) {
      print('❌ Error sending FCM token to backend: $e');
    }
  }

  void _setupFCMListeners() {
    print('🔍 DEBUG: Setting up FCM listeners...');
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 FCM Foreground message received in BottomNav');
      _handleIncomingNotification(message, isFromFCM: true);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 FCM App opened from notification in BottomNav');
      _handleNotificationTap(message);
    });

    _handleInitialNotification();

    _fcm.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed in BottomNav: $newToken');
      _sendRefreshedTokenToBackend(newToken);
    });

    print('✅ DEBUG: FCM listeners setup completed');
  }

  Future<void> _sendRefreshedTokenToBackend(String newToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null && userId.isNotEmpty) {
        print('🔄 Sending refreshed FCM token to backend...');
        print('🪙 New FCM Token: $newToken');
        
        // TODO: Send refreshed token to your backend API
        // await ApiService().updateFCMToken(userId, newToken);
        
        print('✅ Refreshed FCM token sent to backend successfully');
      }
    } catch (e) {
      print('❌ Error sending refreshed FCM token to backend: $e');
    }
  }

  Future<void> _handleInitialNotification() async {
    try {
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        print('📱 FCM Initial message found: ${initialMessage.messageId}');
        _handleNotificationTap(initialMessage);
      } else {
        print('📱 No initial FCM message found');
      }
    } catch (e) {
      print('❌ ERROR handling initial notification: $e');
    }
  }

  void _handleIncomingNotification(RemoteMessage message, {bool isFromFCM = false}) {
    print('📱 Handling incoming notification in BottomNav');
    
    final notification = message.notification;
    final data = message.data;

    String title = 'New Notification';
    String body = 'You have a new message';

    if (notification != null) {
      title = notification.title ?? title;
      body = notification.body ?? body;
    } else if (data.isNotEmpty) {
      title = data['title'] ?? data['notificationTitle'] ?? title;
      body = data['body'] ?? data['notificationBody'] ?? data['message'] ?? body;
    }

    _showCustomPushNotification(title, body);
    _incrementNotificationCount();
    _updateAppIconBadge();

    print('📱 Notification handled - Title: $title, Body: $body, From FCM: $isFromFCM');
    
    _refetchNotifications();
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('📱 Notification tapped, navigating to notifications page');
    
    if (mounted) {
      _navigateToTab(2);
    }
    
    _refetchNotifications();
  }

  void _navigateToTab(int index) {
    if (index >= 0 && index < pages.length) {
      setState(() {
        currentTabIndex = index;
      });
      
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      if (index == 2) {
        _markNotificationsAsRead();
      }
    }
  }

  Future<void> _checkBadgeSupport() async {
    try {
      bool isSupported = await FlutterAppBadger.isAppBadgeSupported();
      print('🛎️ App badge supported: $isSupported');
    } catch (e) {
      print("❌ Error checking badge support: $e");
    }
  }

  Future<void> _updateAppIconBadge() async {
    try {
      if (notificationCount > 0) {
        await FlutterAppBadger.updateBadgeCount(notificationCount);
        print('🛎️ Updated app badge count: $notificationCount');
      } else {
        await FlutterAppBadger.removeBadge();
        print('🛎️ Removed app badge');
      }
    } catch (e) {
      print("❌ Error updating app icon badge: $e");
    }
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');
      
      if (mounted) {
        setState(() {
          userId = storedUserId;
        });
      }
      
      print('👤 User ID loaded: $userId');
      
      if (userId != null && userId!.isNotEmpty) {
        await _loadUserData();
        await _loadNotificationCountFromStorage();
        _setupSocketListener();
      } else {
        setState(() => isLoadingUser = false);
      }
      
    } catch (e) {
      print("❌ Error loading user ID: $e");
      setState(() => isLoadingUser = false);
    }
  }

  Future<void> _loadNotificationCountFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCount = prefs.getInt('notification_count') ?? 0;
      if (mounted) {
        setState(() {
          notificationCount = savedCount;
        });
        _updateAppIconBadge();
      }
      
      print('📊 Loaded notification count from storage: $savedCount');
      await _loadNotificationCountFromAPI();
    } catch (e) {
      print("❌ Error loading notification count from storage: $e");
      await _loadNotificationCountFromAPI();
    }
  }

  Future<void> _saveNotificationCountToStorage(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_count', count);
      print('💾 Saved notification count to storage: $count');
    } catch (e) {
      print("❌ Error saving notification count to storage: $e");
    }
  }

  Future<void> _loadUserData() async {
    if (userId == null || userId!.isEmpty) {
      setState(() => isLoadingUser = false);
      return;
    }

    try {
      setState(() => isLoadingUser = true);
      final response = await ApiService().getAUser(userId!);
      
      if (mounted) {
        setState(() {
          userData = response.data['data'] ?? {};
        });
      }
      print('👤 User data loaded successfully');
      print('📸 User picture data: ${userData['picture']}'); // Debug print
    } catch (e) {
      print("❌ Error loading user data: $e");
      showTopSnackBar(context, "Error loading user data", isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoadingUser = false);
      }
    }
  }

  Future<void> _loadNotificationCountFromAPI() async {
    if (userId == null || userId!.isEmpty) {
      return;
    }

    try {
      final response = await ApiService().getAllNotificationUnRead(userId!);
      
      List<dynamic> notifications = [];
      
      if (response.data is List) {
        notifications = response.data as List<dynamic>;
      } else if (response.data?['notifications'] is List) {
        notifications = response.data!['notifications'] as List<dynamic>;
      } else if (response.data?['data'] is List) {
        notifications = response.data!['data'] as List<dynamic>;
      }
            
      final unreadCount = notifications.where((notification) {
        final userIsRead = notification['userIsRead'] ?? true;
        final isRead = notification['isRead'] ?? true;
        
        return userIsRead == false || isRead == false;
      }).length;
            
      if (mounted) {
        setState(() {
          notificationCount = unreadCount;
        });
        await _saveNotificationCountToStorage(unreadCount);
        _updateAppIconBadge();
      }
      
      print('📊 Loaded notification count from API: $unreadCount');
    } catch (e) {
      print("❌ Error loading notifications from API: $e");
      if (mounted) {
        setState(() {
          notificationCount = 0;
        });
        _updateAppIconBadge();
      }
    }
  }

  void _setupSocketListener() {
    try {
      const String serverUrl = 'https://www.zorrowtek.in';
      
      socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
      });

      socket!.on('connect', (_) {
        print("✅ Connected to server via Socket.IO");
        
        _sendFCMTokenToSocket();
        
        if (userId != null && userId!.isNotEmpty) {
          socket!.emit('joinUserRoom', {'userId': userId});
          print("🚪 Joined user room: $userId");
        }
      });

      socket!.on('disconnect', (_) {
        print("🔌 Disconnected from server");
      });

      socket!.on('error', (error) {
        print('⚠️ Socket error: $error');
      });

      socket!.on('pushNotificationPhone', (data) {
        print('📡 Socket notification received: $data');
        
        final notificationUserId = data['userId']?.toString();
        final message = data['message']?.toString() ?? 'New notification';
        final title = data['title']?.toString() ?? 'New Notification';
        
        if (notificationUserId == userId) {
          print('📱 Processing socket notification for current user');
          
          final remoteMessage = RemoteMessage(
            notification: RemoteNotification(
              title: title,
              body: message,
            ),
            data: data is Map<String, dynamic> ? data : {'fromSocket': 'true'},
          );
          
          _handleIncomingNotification(remoteMessage, isFromFCM: false);
        }
      });

      socket!.on('profile', (data) {
        print('📡 Profile update socket event received: $data');
        
        final profileUserId = data['userId']?.toString();
        
        if (profileUserId == userId) {
          print('🔄 Processing profile update for current user');
          _refreshUserData();
        }
      });

      socket!.connect();
      print('🔌 Socket.IO connection initiated');

    } catch (e) {
      print('❌ Error setting up socket: $e');
    }
  }

  Future<void> _refreshUserData() async {
    if (userId == null || userId!.isEmpty) {
      return;
    }

    try {
      print('🔄 Refreshing user data after profile update...');
      
      final response = await ApiService().getAUser(userId!);
      
      if (mounted) {
        setState(() {
          userData = response.data['data'] ?? {};
        });
      }
      
      print('✅ User data refreshed successfully after profile update');
      
    } catch (e) {
      print('❌ Error refreshing user data: $e');
      if (mounted) {
        showTopSnackBar(context, "Error refreshing profile data", isError: true);
      }
    }
  }

  Future<void> _sendFCMTokenToSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');
      
      if (fcmToken != null && socket != null && socket!.connected) {
        print('📡 Sending FCM token to socket...');
        socket!.emit('registerFCMToken', {
          'userId': userId,
          'fcmToken': fcmToken,
        });
        print('✅ FCM token sent to socket successfully');
      }
    } catch (e) {
      print('❌ Error sending FCM token to socket: $e');
    }
  }

  Future<void> _refetchNotifications() async {
    try {
      print('🔄 Refetching notifications from API...');
      await _loadNotificationCountFromAPI();
    } catch (e) {
      print("❌ Error refetching notifications: $e");
    }
  }

  void _incrementNotificationCount() {
    if (mounted) {
      setState(() {
        notificationCount++;
        _saveNotificationCountToStorage(notificationCount);
      });
      _updateAppIconBadge(); 
      print('➕ Incremented notification count: $notificationCount');
    }
  }

  void _showCustomPushNotification(String title, String message) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              _removeOverlay();
              if (mounted) {
                _navigateToTab(2);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: _removeOverlay,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 5), _removeOverlay);
    
    print('📱 Custom push notification shown: $title');
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      print('📱 Custom notification overlay removed');
    }
  }

  void _markNotificationsAsRead() {
    if (mounted) {
      setState(() {
        notificationCount = 0;
        _saveNotificationCountToStorage(0);
      });
      _updateAppIconBadge();       
      print('📱 Notifications marked as read');
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _pageController.dispose();
    socket?.disconnect();
    socket?.close();
    print('🔄 BottomNav disposed');
    super.dispose();
  }

  Widget _buildNotificationWithBadge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          currentTabIndex == 2 ? Icons.notifications : Icons.notifications_outlined,
          color: Colors.white,
          size: 32.0,
        ),
        if (notificationCount > 0)
          Positioned(
            right: -5,
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                notificationCount > 99 ? '99+' : notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // Helper method to safely get profile image URL from your data structure
  String? _getProfileImageUrl() {
    final picture = userData['picture'];
    
    if (picture == null) return null;
    
    // Handle your specific image structure: { imageUrl: { type: String }, public_id: { type: String } }
    if (picture is Map) {
      // Check if imageUrl exists in the picture map
      if (picture['imageUrl'] != null) {
        final imageUrl = picture['imageUrl'];
        // Handle if imageUrl is a Map with type field or direct string
        if (imageUrl is Map && imageUrl['type'] != null) {
          return imageUrl['type'] as String?;
        } else if (imageUrl is String && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }
      
      // Also check if picture itself has a url field (fallback)
      if (picture['url'] is String) {
        final url = picture['url'] as String;
        if (url.isNotEmpty) return url;
      }
      
      // Check if picture has a direct string value
      if (picture['type'] is String) {
        final type = picture['type'] as String;
        if (type.isNotEmpty) return type;
      }
    }
    
    // If picture is directly a string (fallback)
    if (picture is String && picture.isNotEmpty) {
      return picture;
    }
    
    return null;
  }

  // New method to build the profile icon with user image
  Widget _buildProfileIcon() {
    String? profileImageUrl = _getProfileImageUrl();
    
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      // User has profile image - show circular image
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            profileImageUrl,
            fit: BoxFit.cover,
            width: 36,
            height: 36,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Error loading profile image: $error');
              // Fallback to icon if image fails to load
              return Container(
                color: Colors.white,
                child: Icon(
                  currentTabIndex == 3 ? Icons.person : Icons.person_outline,
                  color: Colors.green,
                  size: 20,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.white,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      // No profile image - show default icon
      return Icon(
        currentTabIndex == 3 ? Icons.person : Icons.person_outline,
        color: Colors.white,
        size: 32.0,
      );
    }
  }

  // Updated navigation items builder
  Widget _buildNavItem(int index) {
    switch (index) {
      case 0:
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Icon(
            currentTabIndex == 0 ? Icons.home : Icons.home_outlined,
            color: Colors.white,
            size: 32.0,
          ),
        );
      case 1:
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Icon(
            currentTabIndex == 1 ? Icons.calendar_today : Icons.calendar_today_outlined,
            color: Colors.white,
            size: 32.0,
          ),
        );
      case 2:
        return _buildNotificationWithBadge();
      case 3:
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: _buildProfileIcon(),
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    print("🎯 Current notification count: $notificationCount");
    print("👤 User ID: $userId");
    print("📱 Current tab index: $currentTabIndex");
    print("🖼️ Profile image URL: ${_getProfileImageUrl()}");
    
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            currentTabIndex = index;
            if (index == 2) {
              print("📢 Marking notifications as read from swipe");
              _markNotificationsAsRead();
            }
          });
        },
        children: pages,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        height: 68,
        backgroundColor: const Color(0xFFECFDF5),
        color: const Color(0xFF28A745),
        animationDuration: const Duration(milliseconds: 300),
        items: <Widget>[
          _buildNavItem(0),
          _buildNavItem(1),
          _buildNavItem(2),
          _buildNavItem(3),
        ],
        onTap: (index) {
          _navigateToTab(index);
        },
        index: currentTabIndex,
      ),
    );
  }
}