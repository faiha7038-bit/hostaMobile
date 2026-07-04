
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
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
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
      await _firebaseMsg.initFCM();
      _setupFCMListeners();
      await _sendFCMTokenToBackend();
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _sendFCMTokenToBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final fcmToken = prefs.getString('fcm_token');
    final userId = prefs.getString('userId');
    if (userId == null || fcmToken == null) {
      return;
    }
  }

  void _setupFCMListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleIncomingNotification(message, isFromFCM: true);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
    _handleInitialNotification();
    _fcm.onTokenRefresh.listen((newToken) {
      _sendRefreshedTokenToBackend(newToken);
    });
  }

  Future<void> _sendRefreshedTokenToBackend(String newToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null && userId.isNotEmpty) {
        // Token refresh logic
      }
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _handleInitialNotification() async {
    try {
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      // Error handling
    }
  }

  void _handleIncomingNotification(RemoteMessage message, {bool isFromFCM = false}) {
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
    _refetchNotifications();
  }

  void _handleNotificationTap(RemoteMessage message) {
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
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _updateAppIconBadge() async {
    try {
      if (notificationCount > 0) {
        await FlutterAppBadger.updateBadgeCount(notificationCount);
      } else {
        await FlutterAppBadger.removeBadge();
      }
    } catch (e) {
      // Error handling
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
      if (userId != null && userId!.isNotEmpty) {
        await _loadUserData();
        await _loadNotificationCountFromStorage();
      } else {
        setState(() => isLoadingUser = false);
      }
    } catch (e) {
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
    } catch (e) {
      // Error handling
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
      final locallyReadIds = prefs.getStringList('locally_read_ids_$userId') ?? [];
      final localReadCount = locallyReadIds.length;
      if (mounted) {
        setState(() {
          notificationCount = savedCount;
        });
        _updateAppIconBadge();
      }
      await _loadNotificationCountFromAPI();
    } catch (e) {
      await _loadNotificationCountFromAPI();
    }
  }

  Future<void> _saveNotificationCountToStorage(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_count_$userId', count);
      await prefs.setInt('notification_count', count);
    } catch (e) {
      // Error handling
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
          if (mounted && notificationCount != unreadCount) {
            setState(() {
              notificationCount = unreadCount;
            });
            await _saveNotificationCountToStorage(unreadCount);
            _updateAppIconBadge();
          }
        } else {
          await _loadNotificationCountFromNotifications();
        }
      } catch (e) {
        await _loadNotificationCountFromNotifications();
      }
    });
  }

  Future<void> _loadNotificationCountFromNotifications() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getNotificationsByRole('user', userId!, page: 1, limit: 100);
      if (response.data['success'] == true) {
        final notificationList = response.data['data'] as List? ?? [];
        final unreadCount = notificationList.where((notification) {
          final userReadStatus = notification['userReadStatus'] as Map? ?? {};
          final isRead = userReadStatus[userId] == true;
          return !isRead;
        }).length;
        if (mounted) {
          setState(() {
            notificationCount = unreadCount;
          });
          await _saveNotificationCountToStorage(unreadCount);
          _updateAppIconBadge();
        }
      }
    } catch (e) {
      // Error handling
    }
  }

  void _markNotificationsAsRead() {
    if (mounted && notificationCount > 0) {
      setState(() {
        notificationCount = 0;
        _saveNotificationCountToStorage(0);
        FlutterAppBadger.removeBadge();
      });
      _markAllNotificationsAsReadOnServer();
    }
  }

  Future<void> _markAllNotificationsAsReadOnServer() async {
    if (userId == null || userId!.isEmpty) return;
    try {
      final apiService = ApiService();
      final response = await apiService.markAllAsRead('user', userId!);
      if (response.data['success'] == true) {
        if (mounted) {
          setState(() {
            notificationCount = 0;
          });
          await _saveNotificationCountToStorage(0);
          FlutterAppBadger.removeBadge();
        }
      }
    } catch (e) {
      // Error handling
    }
  }

  void _incrementNotificationCount() {
    if (mounted) {
      setState(() {
        notificationCount++;
        _saveNotificationCountToStorage(notificationCount);
      });
      _updateAppIconBadge();
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
    }
  }

  void updateNotificationCount(int count) {
    if (mounted) {
      setState(() {
        notificationCount = count;
        _saveNotificationCountToStorage(count);
      });
      if (count > 0) {
        FlutterAppBadger.updateBadgeCount(count);
      } else {
        FlutterAppBadger.removeBadge();
      }
    }
  }

  Future<void> _refetchNotifications() async {
    try {
      await _loadNotificationCountFromAPI();
    } catch (e) {
      // Error handling
    }
  }

  // ==================== PHONE CALL ====================
  Future<void> makePhoneCall(String phoneNumber) async {
    var status = await Permission.phone.request();
    if (status.isGranted) {
      bool? res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
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
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
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

  Widget _navItem({
    required IconData icon,
    required int index,
  }) {
    bool isSelected = currentTabIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 3) {
          _markNotificationsAsRead();
        }
        _navigateToTab(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.05),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.065,
            ),
            if (index == 3 && notificationCount > 0)
              Positioned(
                right: -MediaQuery.of(context).size.width * 0.015,
                top: -MediaQuery.of(context).size.width * 0.015,
                child: Container(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$notificationCount",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.025,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== DISPOSE ====================
  @override
  void dispose() {
    _removeOverlay();
    _pageController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
        height: MediaQuery.of(context).size.height * 0.085,
        decoration: BoxDecoration(
          color: const Color(0xFF34C759),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              icon: Icons.home_rounded,
              index: 0,
            ),
            _navItem(
              icon: Icons.calendar_month_rounded,
              index: 1,
            ),
            // Emergency button center
            GestureDetector(
              onTap: () {
                makePhoneCall("9567900329");
              },
              child: Container(
                height: screenWidth * 0.13,
                width: screenWidth * 0.13,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_call,
                  color: Colors.red,
                  size: screenWidth * 0.07,
                ),
              ),
            ),
            _navItem(
              icon: Icons.notifications_rounded,
              index: 3,
            ),
            _navItem(
              icon: Icons.person_rounded,
              index: 4,
            ),
          ],
        ),
      ),
    );
  }
}