import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger_plus/flutter_app_badger_plus.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/firebase_msg.dart';
import 'package:hosta/presentation/screens/profile_show/profile.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  static final GlobalKey<BottomNavState> navigatorKey = GlobalKey<BottomNavState>();

  int currentTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int notificationCount = 0;
  Map<String, dynamic> userData = {};
  bool isLoadingUser = true;
  String? userId;
  OverlayEntry? _overlayEntry;
  Timer? _refreshTimer;
  late PageController _pageController;

  final FirebaseMsg _firebaseMsg = FirebaseMsg();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  final List<GlobalKey> _pageKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];

  late List<Widget> pages;
  static final GlobalKey<BottomNavState> botttomNavKey = GlobalKey<BottomNavState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentTabIndex);
    _initializePages();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadUserId();
    await _setupSocket();
    await _initializeFCM();
    _startPeriodicRefresh();
  }

  Future<void> _setupSocket() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    final token = prefs.getString("authToken");
    if (userId != null && token != null) {
      final socketService = SocketService();
      socketService.connect(token);
      socketService.joinUserRoom(userId!);
      print("✅ Socket connected: $userId");
    } else {
      print("❌ Socket skipped (missing userId/token)");
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        print('🔄 Periodic refresh checking notification count...');
        _loadNotificationCountFromAPI();
      }
    });
  }

  void _initializePages() {
    pages = [
      Home(key: ValueKey('home_page')),
      BookingScreen(key: _pageKeys[1]),
      Notifications(key: ValueKey('notifications_page')),
      ProfilePage(key: _pageKeys[3]),
    ];
  }

  // ==================== FCM METHODS ====================
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
    final prefs = await SharedPreferences.getInstance();
    final fcmToken = prefs.getString('fcm_token');
    final userId = prefs.getString('userId');
    if (userId == null || fcmToken == null) {
      print("❌ Skipping FCM send: missing data");
      return;
    }
    print("🚀 Sending FCM token for userId=$userId");
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

  // ==================== NAVIGATION METHODS ====================
  void _navigateToTab(int index) {
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
      if (index == 0) {
        _loadNotificationCountFromAPI();
      }
    }
  }

  // ==================== BADGE METHODS ====================
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

  // ==================== USER DATA METHODS ====================
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
      } else {
        setState(() => isLoadingUser = false);
      }
    } catch (e) {
      print("❌ Error loading user ID: $e");
      setState(() => isLoadingUser = false);
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
    } catch (e) {
      print("❌ Error loading user data: $e");
    } finally {
      if (mounted) {
        setState(() => isLoadingUser = false);
      }
    }
  }

  // ==================== NOTIFICATION COUNT METHODS ====================
  Future<void> _loadNotificationCountFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCount = prefs.getInt('unread_count_$userId') ?? 0;
      print('📊 Loaded notification count from storage: $savedCount');
      final locallyReadIds = prefs.getStringList('locally_read_ids_$userId') ?? [];
      final localReadCount = locallyReadIds.length;
      print('📊 Local read count: $localReadCount');
      if (mounted) {
        setState(() {
          notificationCount = savedCount;
        });
        _updateAppIconBadge();
      }
      await _loadNotificationCountFromAPI();
    } catch (e) {
      print("❌ Error loading notification count from storage: $e");
      await _loadNotificationCountFromAPI();
    }
  }

  Future<void> _saveNotificationCountToStorage(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_count_$userId', count);
      await prefs.setInt('notification_count', count);
      print('💾 Saved notification count to storage: $count');
    } catch (e) {
      print("❌ Error saving notification count to storage: $e");
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
        final response = await apiService.getNotificationsByRole(
          'user',
          userId!,
          page: 1,
          limit: 100,
        );
        print('📊 Notifications list response: ${response.data['success']}');
        if (response.data['success'] == true) {
          final notificationList = response.data['data'] as List? ?? [];
          int unreadCount = 0;
          final prefs = await SharedPreferences.getInstance();
          final locallyReadIds = prefs.getStringList('locally_read_ids_$userId') ?? [];
          final localReadSet = locallyReadIds.toSet();
          for (var notification in notificationList) {
            final notificationId = notification['id']?.toString() ?? '';
            final userReadStatus = notification['userReadStatus'] as Map? ?? {};
            final isReadFromServer = userReadStatus[userId] == true;
            final isReadLocally = localReadSet.contains(notificationId);
            final isRead = isReadFromServer || isReadLocally;
            if (!isRead) {
              unreadCount++;
            }
          }
          print('📊 Unread count from API: $unreadCount');
          if (mounted && notificationCount != unreadCount) {
            setState(() {
              notificationCount = unreadCount;
            });
            await _saveNotificationCountToStorage(unreadCount);
            _updateAppIconBadge();
          }
          print('📊 Loaded unread count from API: $unreadCount');
        } else {
          await _loadNotificationCountFromNotifications();
        }
      } catch (e) {
        print("❌ Error loading unread count from API: $e");
        await _loadNotificationCountFromNotifications();
      }
    });
  }

  Future<void> _loadNotificationCountFromNotifications() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getNotificationsByRole('user', userId!, page: 1, limit: 100);
      print('📊 Notifications list response: ${response.data['success']}');
      if (response.data['success'] == true) {
        final notificationList = response.data['data'] as List? ?? [];
        final unreadCount = notificationList.where((notification) {
          final userReadStatus = notification['userReadStatus'] as Map? ?? {};
          final isRead = userReadStatus[userId] == true;
          return !isRead;
        }).length;
        print('📊 Unread count from notifications list: $unreadCount');
        if (mounted) {
          setState(() {
            notificationCount = unreadCount;
          });
          await _saveNotificationCountToStorage(unreadCount);
          _updateAppIconBadge();
        }
        print('📊 Loaded unread count from notifications: $unreadCount');
      }
    } catch (e) {
      print("❌ Error loading from notifications: $e");
    }
  }

  void _markNotificationsAsRead() {
    if (mounted && notificationCount > 0) {
      setState(() {
        notificationCount = 0;
        _saveNotificationCountToStorage(0);
        FlutterAppBadger.removeBadge();
      });
      print('📱 Notifications marked as read locally');
      _markAllNotificationsAsReadOnServer();
    }
  }

  Future<void> _markAllNotificationsAsReadOnServer() async {
    if (userId == null || userId!.isEmpty) return;
    try {
      final apiService = ApiService();
      final response = await apiService.markAllAsRead('user', userId!);
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
    } catch (e) {
      print('❌ Error marking all as read on server: $e');
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
    print('📊 updateNotificationCount called with: $count');
    print('📊 Current notificationCount before: $notificationCount');
    if (mounted) {
      setState(() {
        notificationCount = count;
        _saveNotificationCountToStorage(count);
      });
      if (count > 0) {
        FlutterAppBadger.updateBadgeCount(count);
        print('🛎️ App badge updated to: $count');
      } else {
        FlutterAppBadger.removeBadge();
        print('🛎️ App badge removed');
      }
      print('📊 notificationCount after: $notificationCount');
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

  // ==================== PHONE CALL ====================
  Future<void> makePhoneCall(String phoneNumber) async {
    var status = await Permission.phone.request();
    print("Permission: $status");
    if (status.isGranted) {
      bool? res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
      print("Result: $res");
    } else {
      print("Phone permission denied");
    }
  }

  // ==================== OVERLAY METHODS ====================
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

  // ==================== UI BUILD METHODS ====================
  String? _getProfileImageUrl() {
    final picture = userData['picture'];
    if (picture == null) return null;
    if (picture is Map) {
      if (picture['imageUrl'] != null) {
        final imageUrl = picture['imageUrl'];
        if (imageUrl is Map && imageUrl['type'] != null) {
          return imageUrl['type'] as String?;
        } else if (imageUrl is String && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }
      if (picture['url'] is String) {
        final url = picture['url'] as String;
        if (url.isNotEmpty) return url;
      }
      if (picture['type'] is String) {
        final type = picture['type'] as String;
        if (type.isNotEmpty) return type;
      }
    }
    if (picture is String && picture.isNotEmpty) {
      return picture;
    }
    return null;
  }

  // ─── Responsive icon builder ──────────────────────────────────────────────
  Widget _buildNotificationWithBadge(double iconSize, double badgeSize, double badgeTextSize) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          currentTabIndex == 3
              ? Icons.notifications
              : Icons.notifications_outlined,
          color: Colors.white,
          size: iconSize,
        ),
        if (notificationCount > 0)
          Positioned(
            right: -badgeSize * 0.2,
            top: -badgeSize * 0.2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$notificationCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: badgeTextSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileIcon(double iconSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    String? profileImageUrl = _getProfileImageUrl();

    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return Container(
        width: iconSize,
        height: iconSize,
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
            width: iconSize,
            height: iconSize,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Error loading profile image: $error');
              return Container(
                color: Colors.white,
                child: Icon(
                  currentTabIndex == 4 ? Icons.person : Icons.person_outline,
                  color: Colors.green,
                  size: iconSize,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.white,
                child: Center(
                  child: SizedBox(
                    width: iconSize * 0.5,
                    height: iconSize * 0.5,
                    child: CircularProgressIndicator(
                      strokeWidth: iconSize * 0.08,
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
      return Icon(
        currentTabIndex == 4 ? Icons.person : Icons.person_outline,
        color: Colors.white,
        size: iconSize,
      );
    }
  }

  // ==================== DISPOSE ====================
  @override
  void dispose() {
    _removeOverlay();
    _pageController.dispose();
    _refreshTimer?.cancel();
    print('🔄 BottomNav disposed');
    super.dispose();
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // ─── Responsive dimensions ──────────────────────────────────────────────
    final double iconSize = screenWidth * 0.06;          // ~21.6–24.8 on typical phones
    final double badgeSize = iconSize * 0.75;            // ~16–18.6
    final double badgeTextSize = badgeSize * 0.55;       // ~8.8–10.2
    final double callIconSize = iconSize * 1.2;          // slightly larger for call button

    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          int navIndex = index;
          if (index >= 2) {
            navIndex = index + 1;
          }
          setState(() {
            currentTabIndex = navIndex;
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
              return;
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
          // Let each item define its own icon size for full control
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                currentTabIndex == 0 ? Icons.home : Icons.home_outlined,
                color: Colors.white,
                size: iconSize,
              ),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                currentTabIndex == 1
                    ? Icons.calendar_month
                    : Icons.calendar_month_outlined,
                color: Colors.white,
                size: iconSize,
              ),
              label: "Bookings",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.add_call,
                color: Colors.red,
                size: callIconSize,
              ),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: _buildNotificationWithBadge(iconSize, badgeSize, badgeTextSize),
              label: "Notifications",
            ),
            BottomNavigationBarItem(
              icon: _buildProfileIcon(iconSize),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}