
import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/notification/notification_details.dart';
import 'package:hosta/services/fcm_service.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hosta/presentation/widgets/bottomnav.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> filteredList = [];
  bool isLoading = true;
  String? userId;
  String selectedDate = "";
  bool showUnread = false;
  bool showRead = false;
  String? errorMessage;
  
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;
  bool _isRefreshing = false;
  
  Set<String> locallyReadIds = {};
  
  late ScrollController _scrollController;
  final List<Function(dynamic)> _listenerCallbacks = [];
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _setup();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }
  
  Future<void> _setup() async {
    await _getUserId();
    await _requestNotificationPermission();
    await _initializeNotifications();

    if (userId != null && userId!.isNotEmpty) {
      await _loadLocalReadStatus();
      await FCMService.initialize();
      await FCMService.subscribeToTopic('user_$userId');
      await _fetchNotifications();
      await _loadSavedBadgeCount();
      
      _setupSocketListener();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        try {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          
          if (androidInfo.version.sdkInt >= 33) {
            final status = await Permission.notification.status;
            
            if (!status.isGranted) {
              final result = await Permission.notification.request();
              
              if (result.isPermanentlyDenied) {
                await openAppSettings();
              }
            }
          }
        } catch (e) {
          final status = await Permission.notification.status;
          if (!status.isGranted) {
            await Permission.notification.request();
          }
        }
      } else if (Platform.isIOS) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }
    } catch (e) {
      // Handle permission error silently
    }
  }
  
  @override
  void dispose() {
    final socketService = SocketService();
    for (final callback in _listenerCallbacks) {
      // Listeners will be cleared when socket disconnects
    }
    
    if (userId != null) {
      FCMService.unsubscribeFromTopic('user_$userId');
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings = 
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
        },
      );

      if (Platform.isAndroid) {
        final vibrationPattern = Int64List(5)
          ..[0] = 0
          ..[1] = 500
          ..[2] = 200
          ..[3] = 500
          ..[4] = 0;
          
        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications',
          importance: Importance.max,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          sound: const RawResourceAndroidNotificationSound('notification_sound'),
        );
        
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
    } catch (e) {
      // Handle initialization error silently
    }
  }

  Future<void> _showLocalNotification(Map<String, dynamic> data) async {
    try {
      final vibrationPattern = Int64List(5)
        ..[0] = 0
        ..[1] = 500
        ..[2] = 200
        ..[3] = 500
        ..[4] = 0;
      
      final AndroidNotificationDetails androidPlatformChannelSpecifics = 
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        styleInformation: BigTextStyleInformation(
          data['message'] ?? 'You have a new notification',
        ),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics = 
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000).toInt();
      
      await flutterLocalNotificationsPlugin.show(
        id,
        data['title'] ?? 'New Notification',
        data['message'] ?? 'You have a new notification',
        platformChannelSpecifics,
        payload: data['id']?.toString(),
      );
    } catch (e) {
      // Handle notification show error silently
    }
  }

  Future<void> _loadLocalReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getStringList('locally_read_ids_$userId') ?? [];
      locallyReadIds = savedIds.toSet();
    } catch (e) {
      // Handle load error silently
    }
  }

  Future<void> _saveLocalReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('locally_read_ids_$userId', locallyReadIds.toList());
    } catch (e) {
      // Handle save error silently
    }
  }

  void _updateBottomNavBadge(int count) {
    try {
      final bottomNavState = BottomNavState.navigatorKey.currentState;
      if (bottomNavState != null) {
        bottomNavState.updateNotificationCount(count);
        return;
      }
    } catch (e) {
      // Handle update error silently
    }
    
    try {
      final bottomNavState = context.findAncestorStateOfType<BottomNavState>();
      if (bottomNavState != null) {
        bottomNavState.updateNotificationCount(count);
        return;
      }
    } catch (e) {
      // Handle update error silently
    }
    
    _updateBadgeViaSharedPreferences(count);
  }

  Future<void> _updateBadgeViaSharedPreferences(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_count', count);
      await prefs.setInt('unread_count_$userId', count);
    } catch (e) {
      // Handle save error silently
    }
  }

  Future<void> _fetchNotifications({bool isLoadMore = false}) async {
    if (userId == null || userId!.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    if (isLoadMore && (_isLoadingMore || !_hasMorePages)) {
      return;
    }

    if (!isLoadMore) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        _currentPage = 1;
        notifications = [];
        _hasMorePages = true;
        _totalCount = 0;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final apiService = ApiService();
      await apiService.init();
      
      final response = await apiService.getNotificationsByRole(
        'user',
        userId!,
        page: _currentPage,
        limit: 10,
      );

      if (response.data['success'] == true) {
        final notificationList = response.data['data'];
        _totalCount = response.data['count'] ?? 0;
        
        final limit = 10;
        _totalPages = _totalCount > 0 ? (_totalCount / limit).ceil() : 1;
        _hasMorePages = _currentPage < _totalPages;
        
        List<Map<String, dynamic>> myNotifications = [];
        
        if (notificationList is List) {
          for (var item in notificationList) {
            try {
              Map<String, dynamic> notification;
              if (item is Map<String, dynamic>) {
                notification = item;
              } else {
                notification = Map<String, dynamic>.from(item);
              }
              
              final notificationId = notification['id']?.toString() ?? '';
              
              final userReadStatus = notification['userReadStatus'] as Map? ?? {};
              final isReadFromServer = userReadStatus[userId] == true;
              final isReadLocally = locallyReadIds.contains(notificationId);
              final isRead = isReadFromServer || isReadLocally;
              
              myNotifications.add({
                "_id": notificationId,
                "id": notification['id'],
                "message": notification['message'] ?? "No message",
                "createdAt": notification['createdAt'] ?? DateTime.now().toIso8601String(),
                "read": isRead,
                "title": notification['title'] ?? "Notification",
                "data": notification['data'] ?? {},
                "userIds": notification['userIds'] ?? [],
                "hospitalIds": notification['hospitalIds'] ?? [],
                "doctorIds": notification['doctorIds'] ?? [],
                "userReadStatus": userReadStatus,
                "hospitalReadStatus": notification['hospitalReadStatus'] ?? {},
                "doctorReadStatus": notification['doctorReadStatus'] ?? {},
                "staffReadStatus": notification['staffReadStatus'] ?? {},
                "pharmacyReadStatus": notification['pharmacyReadStatus'] ?? {},
                "labReadStatus": notification['labReadStatus'] ?? {},
                "superAdminReadStatus": notification['superAdminReadStatus'] ?? {},
              });
            } catch (e) {
              // Handle individual notification error silently
            }
          }
        }
        
        if (mounted) {
          setState(() {
            if (isLoadMore) {
              notifications.addAll(myNotifications);
            } else {
              notifications = myNotifications;
            }
            
            notifications.sort((a, b) => 
              DateTime.parse(b["createdAt"]).compareTo(DateTime.parse(a["createdAt"]))
            );
            
            _updateFilteredList();
            errorMessage = notifications.isEmpty ? "No notifications found" : null;
            _isLoadingMore = false;
            isLoading = false;
          });
          
          await _updateBadgeCount();
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load notifications');
      }
      
    } catch (e, stacktrace) {
      if (mounted) {
        setState(() {
          errorMessage = "Failed to load notifications";
          _isLoadingMore = false;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (!_hasMorePages || _isLoadingMore || _isRefreshing) {
      return;
    }
    
    _currentPage++;
    await _fetchNotifications(isLoadMore: true);
  }

  Future<void> _loadSavedBadgeCount() async {
    if (userId == null || userId!.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      var savedCount = prefs.getInt('unread_count_$userId') ?? 0;
      if (savedCount == 0) {
        savedCount = prefs.getInt('notification_count') ?? 0;
      }
      _updateBottomNavBadge(savedCount);
    } catch (e) {
      // Handle load error silently
    }
  }

  Future<void> _updateBadgeCount() async {
    if (userId == null || userId!.isEmpty) return;
    
    try {
      final apiService = ApiService();
      await apiService.init();
      
      final response = await apiService.getUnreadCount('user', userId!);
      
      if (response.data['success'] == true) {
        var unreadCount = response.data['count'] ?? 0;
        
        final localReadCount = locallyReadIds.length;
        final finalCount = unreadCount > localReadCount ? unreadCount - localReadCount : 0;
        
        _updateBottomNavBadge(finalCount);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_count', finalCount);
        await prefs.setInt('unread_count_$userId', finalCount);
      } else {
        final unreadCount = notifications.where((n) => n["read"] != true).length;
        _updateBottomNavBadge(unreadCount);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_count', unreadCount);
        await prefs.setInt('unread_count_$userId', unreadCount);
      }
    } catch (e) {
      final unreadCount = notifications.where((n) => n["read"] != true).length;
      _updateBottomNavBadge(unreadCount);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_count', unreadCount);
      await prefs.setInt('unread_count_$userId', unreadCount);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    if (userId == null) return;
    
    locallyReadIds.add(notificationId);
    await _saveLocalReadStatus();
    
    if (mounted) {
      setState(() {
        final index = notifications.indexWhere((n) => n["_id"] == notificationId);
        if (index != -1) {
          notifications[index]["read"] = true;
          _updateFilteredList();
        }
      });
    }
    
    await _updateBadgeCount();
    
    try {
      final apiService = ApiService();
      await apiService.init();
      await apiService.markNotificationAsRead('user', userId!, notificationId);
    } catch (e) {
      // Handle API error silently
    }
    
    final notification = notifications.firstWhere(
      (n) => n["_id"] == notificationId,
      orElse: () => {},
    );
    _navigateToNotificationDetails(notification);
  }

  Future<void> _markAllAsRead() async {
    if (userId == null) {
      _showSnackBar('Please login first', Colors.red);
      return;
    }

    final unreadCount = notifications.where((n) => n["read"] != true).length;
    if (unreadCount == 0) {
      _showSnackBar('No unread notifications', Colors.grey);
      return;
    }
    
    for (var notification in notifications) {
      if (notification["read"] != true) {
        locallyReadIds.add(notification["_id"].toString());
      }
    }
    await _saveLocalReadStatus();
    
    if (mounted) {
      setState(() {
        for (var notification in notifications) {
          notification["read"] = true;
        }
        _updateFilteredList();
      });
    }
    
    _updateBottomNavBadge(0);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_count', 0);
    await prefs.setInt('unread_count_$userId', 0);
    
    _showSnackBar('All notifications marked as read ✓', Colors.green);
    
    try {
      final apiService = ApiService();
      await apiService.init();
      await apiService.markAllAsRead('user', userId!);
    } catch (e) {
      // Handle API error silently
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleBadgeTap() {
    final unreadCount = notifications.where((n) => n["read"] != true).length;
    if (unreadCount == 0) {
      _showSnackBar('No unread notifications', Colors.grey);
      return;
    }
    _markAllAsRead();
  }

  void _setupSocketListener() {
    final socketService = SocketService();
    
    if (userId != null && userId!.isNotEmpty) {
      socketService.joinUserRoom(userId!);
    }
    
    final createdCallback = (data) {
      _handleNewNotification(data);
    };
    _listenerCallbacks.add(createdCallback);
    socketService.addListener(['NOTIFICATION_CREATED'], createdCallback);
    
    final readCallback = (data) {
      _handleNotificationRead(data);
    };
    _listenerCallbacks.add(readCallback);
    socketService.addListener(['NOTIFICATION_READ'], readCallback);
    
    final deletedCallback = (data) {
      _handleNotificationDeleted(data);
    };
    _listenerCallbacks.add(deletedCallback);
    socketService.addListener(['NOTIFICATION_DELETED'], deletedCallback);
  }

  void _handleNewNotification(dynamic data) async {
    if (mounted) {
      final newNotification = {
        "_id": data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        "id": data['id'],
        "message": data['message'] ?? "New notification",
        "createdAt": DateTime.now().toIso8601String(),
        "read": false,
        "title": data['title'] ?? "Notification",
        "data": data['data'] ?? {},
        "userReadStatus": {userId: false},
      };
      
      setState(() {
        notifications.insert(0, newNotification);
        _updateFilteredList();
      });
      
      await _updateBadgeCount();
      _showLocalNotification(data);
    }
  }

  void _handleNotificationRead(dynamic data) {
    if (mounted) {
      setState(() {
        final index = notifications.indexWhere((n) => n["id"] == data['id']);
        if (index != -1) {
          notifications[index]["read"] = true;
          _updateFilteredList();
        }
      });
      _updateBadgeCount();
    }
  }

  void _handleNotificationDeleted(dynamic data) {
    _fetchNotifications();
  }

  void _navigateToNotificationDetails(Map<String, dynamic> notification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailsScreen(
          notification: notification,
        ),
      )
    );
  }

  void _updateFilteredList() {
    filteredList = notifications.where((n) {
      bool matchesRead = (!showUnread && !showRead) ||
          (showUnread && n["read"] != true) ||
          (showRead && n["read"] == true);

      bool matchesDate = selectedDate.isEmpty ||
          DateFormat('yyyy-MM-dd').format(DateTime.parse(n["createdAt"])) ==
              selectedDate;

      return matchesRead && matchesDate;
    }).toList();
  }

  String _getRelativeTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final diff = DateTime.now().difference(dateTime);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d').format(dateTime);
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    
    final unreadCount = notifications.where((n) => n["read"] != true).length;
    final readCount = notifications.where((n) => n["read"] == true).length;
    final horizontalPadding = isSmallScreen ? screenWidth * 0.04 : screenWidth * 0.06;

    if (userId == null || userId!.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFECFDF5),
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: Text(
            "Notifications", 
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.035,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          toolbarHeight: isSmallScreen ? kToolbarHeight : kToolbarHeight * 1.1,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off, 
                size: isSmallScreen ? 80 : 100, 
                color: Colors.grey,
              ),
              SizedBox(height: screenHeight * 0.025),
              Text(
                "Please login to view notifications",
                style: TextStyle(
                  fontSize: isSmallScreen ? screenWidth * 0.04 : screenWidth * 0.03,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Notifications", 
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.035,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        toolbarHeight: isSmallScreen ? kToolbarHeight : kToolbarHeight * 1.1,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh, 
              color: Colors.white,
              size: isSmallScreen ? screenWidth * 0.055 : screenWidth * 0.04,
            ),
            onPressed: () async {
              setState(() => _isRefreshing = true);
              await _fetchNotifications();
              await _updateBadgeCount();
              setState(() => _isRefreshing = false);
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: isSmallScreen ? 4 : 6,
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _isRefreshing = true);
                await _fetchNotifications();
                await _updateBadgeCount();
                setState(() => _isRefreshing = false);
              },
              child: Column(
                children: [
                  // Filter Chips
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: screenHeight * 0.015,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildFilterChip(
                              "Unread ($unreadCount)", 
                              showUnread, 
                              () {
                                setState(() {
                                  showUnread = !showUnread;
                                  showRead = false;
                                  _updateFilteredList();
                                });
                              },
                              screenWidth,
                            ),
                            SizedBox(width: screenWidth * 0.025),
                            _buildFilterChip(
                              "Read ($readCount)", 
                              showRead, 
                              () {
                                setState(() {
                                  showRead = !showRead;
                                  showUnread = false;
                                  _updateFilteredList();
                                });
                              },
                              screenWidth,
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _handleBadgeTap,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03,
                              vertical: screenHeight * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: unreadCount > 0 ? Colors.red : Colors.grey[300],
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.05,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.notifications_active,
                                  color: Colors.white,
                                  size: isSmallScreen 
                                      ? screenWidth * 0.045 
                                      : screenWidth * 0.035,
                                ),
                                SizedBox(width: screenWidth * 0.015),
                                Text(
                                  unreadCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen 
                                        ? screenWidth * 0.035 
                                        : screenWidth * 0.028,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Notifications List
                  Expanded(
                    child: filteredList.isEmpty
                        ? _buildEmptyState(screenWidth, screenHeight, isSmallScreen)
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: filteredList.length + (_hasMorePages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredList.length && _hasMorePages) {
                                return Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(
                                          strokeWidth: isSmallScreen ? 3 : 4,
                                        ),
                                        SizedBox(height: screenHeight * 0.01),
                                        Text(
                                          'Loading more...',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: isSmallScreen 
                                                ? screenWidth * 0.03 
                                                : screenWidth * 0.025,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final n = filteredList[index];
                              return _buildNotificationCard(
                                n, 
                                screenWidth, 
                                screenHeight, 
                                isSmallScreen
                              );
                            },
                          ),
                  ),
                  
                  // Footer
                  if (_totalCount > 0)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                      child: Text(
                        'Showing ${notifications.length} of $_totalCount notifications',
                        style: TextStyle(
                          fontSize: isSmallScreen 
                              ? screenWidth * 0.03 
                              : screenWidth * 0.025,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight, bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: isSmallScreen ? 64 : 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            errorMessage ?? "No notifications",
            style: TextStyle(
              fontSize: isSmallScreen ? screenWidth * 0.04 : screenWidth * 0.03,
              color: Colors.grey[600],
            ),
          ),
          if (_totalCount > 0)
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.01),
              child: Text(
                'Total: $_totalCount notifications',
                style: TextStyle(
                  fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.025,
                  color: Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    double screenWidth,
    double screenHeight,
    bool isSmallScreen,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenHeight * 0.005,
      ),
      elevation: isSmallScreen ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.01,
        ),
        leading: CircleAvatar(
          radius: isSmallScreen 
              ? screenWidth * 0.06 
              : screenWidth * 0.045,
          backgroundColor: notification["read"] == true
              ? Colors.grey[300]
              : Colors.green[100],
          child: Icon(
            notification["read"] == true
                ? Icons.notifications_none
                : Icons.notifications_active,
            color: notification["read"] == true
                ? Colors.grey
                : Colors.green,
            size: isSmallScreen 
                ? screenWidth * 0.055 
                : screenWidth * 0.04,
          ),
        ),
        title: Text(
          notification["message"] ?? "No message",
          style: TextStyle(
            fontWeight: notification["read"] == true
                ? FontWeight.normal
                : FontWeight.bold,
            fontSize: isSmallScreen 
                ? screenWidth * 0.035 
                : screenWidth * 0.028,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _getRelativeTime(notification["createdAt"]),
          style: TextStyle(
            fontSize: isSmallScreen 
                ? screenWidth * 0.03 
                : screenWidth * 0.025,
            color: Colors.grey[600],
          ),
        ),
        trailing: notification["read"] == true
            ? null
            : Container(
                width: screenWidth * 0.025,
                height: screenWidth * 0.025,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          if (notification["read"] != true) {
            _markAsRead(notification["_id"].toString());
          } else {
            _navigateToNotificationDetails(notification);
          }
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label, 
    bool selected, 
    VoidCallback onTap,
    double screenWidth,
  ) {
    final isSmallScreen = screenWidth < 600;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.02,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.green[50],
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
          border: Border.all(
            color: Colors.green.shade200,
            width: screenWidth * 0.0025,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.green[800],
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen 
                ? screenWidth * 0.035 
                : screenWidth * 0.028,
          ),
        ),
      ),
    );
  }
}