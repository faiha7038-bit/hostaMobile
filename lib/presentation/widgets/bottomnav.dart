import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app_badger_plus/flutter_app_badger_plus.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/firebase_msg.dart';
import 'package:hosta/presentation/screens/profile_show/profile.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/home/home.dart';
import '../screens/booking/booking.dart';
import '../screens/notification/notifications.dart';
import '../../services/api_service.dart';

class Bottomnav extends ConsumerStatefulWidget {
  const Bottomnav({super.key});

  @override
  ConsumerState<Bottomnav> createState() => BottomNavState();
}

class BottomNavState extends ConsumerState<Bottomnav> {
  int currentTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int notificationCount = 0;
  Map<String, dynamic> userData = {};
  bool isLoadingUser = true;
  String? userId;
  IO.Socket? socket;
  OverlayEntry? _overlayEntry;
  Timer? _refreshTimer;
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
       Home(key: ValueKey('home_page')),
      BookingScreen(key: _pageKeys[1]),
       Notifications(key: ValueKey('notifications_page')),
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
      _navigateToTab(3);
    }
    
    _refetchNotifications();
  }
  void _navigateToTab(int index) {
  // Skip call button index
  int pageIndex = index;

  if (index > 2) {
    pageIndex = index - 1;
  }

  if (pageIndex >= 0 && pageIndex < pages.length) {
    setState(() {
      currentTabIndex = index;
    });

    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    if (index == 3) {
      _markNotificationsAsRead();
      //_resetBadgeCountOnly();
       } else if (index == 0) {
      _loadNotificationCountFromAPI();
    }
  }
}
// void _resetBadgeCountOnly() {
//   if (mounted && notificationCount > 0) {
//     setState(() {
//       notificationCount = 0;
//       _saveNotificationCountToStorage(0);
//       FlutterAppBadger.removeBadge();
//     });
//     print('📱 Badge count reset when navigating to notifications');
//   }
// }
  // void _navigateToTab(int index) {
  //   if (index >= 0 && index < pages.length) {
  //     setState(() {
  //       currentTabIndex = index;
  //     });
      
  //     _pageController.animateToPage(
  //       index,
  //       duration: const Duration(milliseconds: 300),
  //       curve: Curves.easeInOut,
  //     );
      
  //     if (index == 3) {
  //       _markNotificationsAsRead();
  //     }
  //   }
  // }

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
    } catch (e) 
    {
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
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 500), () async {
    if (userId == null || userId!.isEmpty) {
      return;
    }

    try {
      final apiService = ApiService();
    //   final response = await apiService.getNotificationsByRole('user', userId!);
      final response = await ApiService().getNotifications();
      
      List<dynamic> notifications = [];
       if (response.data is Map && response.data['success'] == true) {
      final data = response.data['data'];
      if (data is List) {
        notifications = data;
      }
    } else if (response.data is List) {
      notifications = response.data;
    }
        
      final unreadCount = notifications.where((notification) {
         final userReadStatus = notification['userReadStatus'] as Map? ?? {};
      final isRead = userReadStatus[userId] == true;
      return !isRead;
      }).length;
             print('📊 Unread notification count: $unreadCount');
      if (mounted && notificationCount != unreadCount) {
        setState(() {
          notificationCount = unreadCount;
        });
        await _saveNotificationCountToStorage(unreadCount);
        _updateAppIconBadge();
      }
      
     // print('📊 Loaded notification count from API: $unreadCount');
    } catch (e) {
      print("❌ Error loading notifications from API: $e");
      // if (mounted) {
      //   setState(() {
      //     notificationCount = 0;
      //   });
      //   _updateAppIconBadge();
      // }
    }
  }
    );
  }
Future<void> makePhoneCall(String phoneNumber) async {
  bool? res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);

  if (res == true) {
    print("Call Started");
  } else {
    print("Call Failed");
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
//9567900329
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + (screenHeight * 0.0125),
        left: screenWidth * 0.025,
        right: screenWidth * 0.025,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              _removeOverlay();
              if (mounted) {
                _navigateToTab(3);
              }
            },
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: screenWidth * 0.025,
                    spreadRadius: screenWidth * 0.005,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: screenWidth * 0.1,
                    height: screenWidth * 0.1,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: Colors.green,
                      size: screenWidth * 0.05,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.0025),
                        Text(
                          message,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.03,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: screenWidth * 0.045,
                    ),
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
    if (mounted && notificationCount > 0) {
      setState(() {
        notificationCount = 0;
        _saveNotificationCountToStorage(0);
        FlutterAppBadger.removeBadge(); 
      });
    //  _updateAppIconBadge(); 
         
      print('📱 Notifications marked as read');
       _markAllNotificationsAsReadOnServer();
    }
  }
  
  Future<void> _markAllNotificationsAsReadOnServer() async {
  if (userId == null || userId!.isEmpty) return;
  
  try {
    final apiService = ApiService();
    final response = await apiService.markAllAsRead('user', userId!);
    // Call your API to mark all as read
   // await apiService.markAllAsRead('user', userId!);
     if (response.data['success'] == true) {
      print('✅ All notifications marked as read on server');
      
      if (mounted) {
        setState(() {
          notificationCount = 0;
        });
        await _saveNotificationCountToStorage(0);
        FlutterAppBadger.removeBadge();
      }
    }
    //print('✅ All notifications marked as read on server');
  } catch (e) {
    print('❌ Error marking all as read on server: $e');
  }
}

  // Call this from notification screen when user clicks a notification
void _decrementBadgeCount() {
  if (mounted && notificationCount > 0) {
    setState(() {
      notificationCount--;
      _saveNotificationCountToStorage(notificationCount);
    });
    
    if (notificationCount == 0) {
      FlutterAppBadger.removeBadge();
    } else {
      FlutterAppBadger.updateBadgeCount(notificationCount);
    }
    print('📱 Badge decreased to: $notificationCount');
  }
}
void updateNotificationCount(int count) {
  if (mounted) {
    setState(() {
      notificationCount = count;
      _saveNotificationCountToStorage(count);
    });
    
    // Update app icon badge
    if (count > 0) {
      FlutterAppBadger.updateBadgeCount(count);
       print('🛎️ App badge updated to: $count');
    } else {
      FlutterAppBadger.removeBadge();
      print('🛎️ App badge removed');
    }
  }
}

  @override
  void dispose() {
    _removeOverlay();
    _pageController.dispose();
    _refreshTimer?.cancel();
    socket?.disconnect();
    socket?.close();
    print('🔄 BottomNav disposed');
    super.dispose();
  }

  Widget _buildNotificationWithBadge() {
     final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
  clipBehavior: Clip.none,
  children: [
    Icon(
      currentTabIndex == 2
          ? Icons.notifications
          : Icons.notifications_outlined,
      color: Colors.white,
      size: screenWidth * 0.08,
    ),

    if (notificationCount > 0)
      Positioned(
        right: -4,
        top: -4,
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Text(
            notificationCount > 99 ? '99+' : '$notificationCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    String? profileImageUrl = _getProfileImageUrl();
    
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      // User has profile image - show circular image
      return Container(
        width: screenWidth * 0.09,
        height: screenWidth * 0.09,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: screenWidth * 0.005,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: screenWidth * 0.01,
              spreadRadius: screenWidth * 0.0025,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            profileImageUrl,
            fit: BoxFit.cover,
            width: screenWidth * 0.09,
            height: screenWidth * 0.09,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Error loading profile image: $error');
              // Fallback to icon if image fails to load
              return Container(
                color: Colors.white,
                child: Icon(
                  currentTabIndex == 4 ? Icons.person : Icons.person_outline,
                  color: Colors.green,
                  size: screenWidth * 0.05,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.white,
                child: Center(
                  child: SizedBox(
                    width: screenWidth * 0.04,
                    height: screenWidth * 0.04,
                    child: CircularProgressIndicator(
                      strokeWidth: screenWidth * 0.005,
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
        currentTabIndex == 4 ? Icons.person : Icons.person_outline,
        color: Colors.white,
        size: screenWidth * 0.08,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
   
    
    print("🎯 Current notification count: $notificationCount");
    print("👤 User ID: $userId");
    print("📱 Current tab index: $currentTabIndex");
    print("🖼️ Profile image URL: ${_getProfileImageUrl()}");
    
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
  int navIndex = index;

  // Adjust because call button exists in navbar
  if (index >= 2) {
    navIndex = index + 1;
  }

  setState(() {
    currentTabIndex = navIndex;

    if (navIndex == 3) {
      _markNotificationsAsRead();
    }
  });
},
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: screenWidth * 0.0025),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentTabIndex,
          onTap: (index) {
             if (index == 2) {
      makePhoneCall("9567900329");
      return; // Don't navigate to a page
    }
            _navigateToTab(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF28A745),
          elevation: screenWidth * 0.025,
          selectedItemColor: const Color(0xFFECFDF5),
          unselectedItemColor: const Color(0xFFECFDF5),
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.03,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: screenWidth * 0.0275,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                currentTabIndex == 0 ? Icons.home : Icons.home_outlined,
                size: screenWidth * 0.07,
              ),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                currentTabIndex == 1
                    ? Icons.calendar_month
                    : Icons.calendar_month_outlined,
                size: screenWidth * 0.07,
              ),
              label: "Bookings",
            ),
                BottomNavigationBarItem(
                  
     icon: IconButton(
  onPressed: () {
    makePhoneCall("9567900329");
  },
  icon: Icon(
    Icons.add_call,
    color: Colors.red,
    size: screenWidth * 0.08,
  ),
),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: _buildNotificationWithBadge(),
              label: "Notifications",
            ),
            BottomNavigationBarItem(
              icon: _buildProfileIcon(),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

