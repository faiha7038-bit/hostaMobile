import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger_plus/flutter_app_badger_plus.dart';
import 'package:hosta/presentation/screens/notification/notification_details.dart';
import 'package:hosta/services/fcm_service.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
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
    // Check if device is Android
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        
        print('📱 Android SDK Version: ${androidInfo.version.sdkInt}');
        
        // Android 13+ (API 33+) needs notification permission
        if (androidInfo.version.sdkInt >= 33) {
          final status = await Permission.notification.status;
          print('📱 Notification permission status: $status');
          
          if (!status.isGranted) {
            final result = await Permission.notification.request();
            print('📱 Notification permission result: $result');
            
            if (result.isGranted) {
              print('✅ Notification permission granted');
            } else if (result.isDenied) {
              print('⚠️ Notification permission denied');
            } else if (result.isPermanentlyDenied) {
              print('⚠️ Notification permission permanently denied');
              // Open app settings
              await openAppSettings();
            }
          } else {
            print('✅ Notification permission already granted');
          }
        } else {
          print('📱 Android version < 33, notification permission not required');
        }
      } catch (e) {
        print('❌ Error getting device info: $e');
        // Fallback: try to request permission anyway
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }
    } else if (Platform.isIOS) {
      // iOS permission handling
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        print('📱 iOS Notification permission result: $result');
      }
    }
  } catch (e) {
    print('❌ Error in notification permission: $e');
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
    print("👤 User ID: $userId");
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
          print('Notification tapped: ${response.payload}');
          if (response.payload != null) {
            // Handle navigation
          }
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
        
        print('✅ Android notification channel created with sound');
      }

      print('✅ Notification plugin initialized successfully');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
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
      
      print("✅ Local notification shown with sound");
    } catch (e) {
      print("❌ Error showing local notification: $e");
    }
  }

  // ==================== LOCAL READ STATUS ====================
  
  Future<void> _loadLocalReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getStringList('locally_read_ids_$userId') ?? [];
      locallyReadIds = savedIds.toSet();
      print('📊 Loaded ${locallyReadIds.length} locally read notifications');
    } catch (e) {
      print('❌ Error loading local read status: $e');
    }
  }

  Future<void> _saveLocalReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('locally_read_ids_$userId', locallyReadIds.toList());
      print('📊 Saved ${locallyReadIds.length} locally read notifications');
    } catch (e) {
      print('❌ Error saving local read status: $e');
    }
  }

  // ==================== BADGE UPDATE ====================
  
  void _updateBottomNavBadge(int count) {
    print('📊 _updateBottomNavBadge called with: $count');
    
    try {
      final bottomNavState = BottomNavState.navigatorKey.currentState;
      if (bottomNavState != null) {
        bottomNavState.updateNotificationCount(count);
        print('📊 Updated via GlobalKey to: $count');
        return;
      }
    } catch (e) {
      print('❌ GlobalKey error: $e');
    }
    
    try {
      final bottomNavState = context.findAncestorStateOfType<BottomNavState>();
      if (bottomNavState != null) {
        bottomNavState.updateNotificationCount(count);
        print('📊 Updated via Ancestor to: $count');
        return;
      }
    } catch (e) {
      print('❌ Ancestor error: $e');
    }
    
    _updateBadgeViaSharedPreferences(count);
  }

  Future<void> _updateBadgeViaSharedPreferences(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_count', count);
      await prefs.setInt('unread_count_$userId', count);
      print('📊 Saved badge count to SharedPreferences: $count');
    } catch (e) {
      print('❌ Error saving badge count: $e');
    }
  }

  // ==================== FETCH NOTIFICATIONS WITH PAGINATION ====================
  
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

      print("📡 Response Status: ${response.statusCode}");
      print("📡 Page: $_currentPage");
      
      if (response.data['success'] == true) {
        final notificationList = response.data['data'];
        _totalCount = response.data['count'] ?? 0;
        
        final limit = 10;
        _totalPages = _totalCount > 0 ? (_totalCount / limit).ceil() : 1;
        _hasMorePages = _currentPage < _totalPages;
        
        print("📦 Total notifications: $_totalCount");
        print("📄 Page $_currentPage of $_totalPages");
        print("📊 Has more pages: $_hasMorePages");
        
        List<Map<String, dynamic>> myNotifications = [];
        
        if (notificationList is List) {
          print("📦 Received ${notificationList.length} notifications");
          
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
              print("⚠️ Error processing notification item: $e");
            }
          }
        }
        
        final totalUnread = myNotifications.where((n) => n["read"] != true).length;
        print("✅ Processed ${myNotifications.length} notifications");
        print("📊 Unread in this page: $totalUnread");
        
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
      print("❌ Error fetching notifications: $e");
      print("📚 Stacktrace: $stacktrace");
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
      print("⏭️ Skipping load more: hasMore=$_hasMorePages, loading=$_isLoadingMore");
      return;
    }
    
    print("📥 Loading more notifications...");
    _currentPage++;
    await _fetchNotifications(isLoadMore: true);
  }

  // ==================== BADGE COUNT ====================
  
  Future<void> _loadSavedBadgeCount() async {
    if (userId == null || userId!.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      var savedCount = prefs.getInt('unread_count_$userId') ?? 0;
      if (savedCount == 0) {
        savedCount = prefs.getInt('notification_count') ?? 0;
      }
      _updateBottomNavBadge(savedCount);
      print('📊 Loaded saved badge count: $savedCount');
    } catch (e) {
      print('❌ Error loading saved badge count: $e');
    }
  }

  Future<void> _updateBadgeCount() async {
    if (userId == null || userId!.isEmpty) return;
    
    try {
      final apiService = ApiService();
      await apiService.init();
      
      final response = await apiService.getUnreadCount('user', userId!);
      print('📊 Unread count response: ${response.data}');
      
      if (response.data['success'] == true) {
        var unreadCount = response.data['count'] ?? 0;
        
        final localReadCount = locallyReadIds.length;
        final finalCount = unreadCount > localReadCount ? unreadCount - localReadCount : 0;
        
        _updateBottomNavBadge(finalCount);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_count', finalCount);
        await prefs.setInt('unread_count_$userId', finalCount);
        
        print('📊 Total unread count: $finalCount (API: $unreadCount, Local: $localReadCount)');
      } else {
        final unreadCount = notifications.where((n) => n["read"] != true).length;
        _updateBottomNavBadge(unreadCount);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_count', unreadCount);
        await prefs.setInt('unread_count_$userId', unreadCount);
      }
    } catch (e) {
      print('❌ Error getting unread count: $e');
      
      final unreadCount = notifications.where((n) => n["read"] != true).length;
      _updateBottomNavBadge(unreadCount);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_count', unreadCount);
      await prefs.setInt('unread_count_$userId', unreadCount);
    }
  }

  // ==================== MARK AS READ ====================
  
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
      print("✅ API mark as read success");
    } catch (e) {
      print('⚠️ API failed, but local read status kept');
    }
    
    final notification = notifications.firstWhere(
      (n) => n["_id"] == notificationId,
      orElse: () => {},
    );
    _navigateToNotificationDetails(notification);
  }

  Future<void> _markAllAsRead() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login first'), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }

    final unreadCount = notifications.where((n) => n["read"] != true).length;
    if (unreadCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No unread notifications'), 
          backgroundColor: Colors.grey
        ),
      );
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications marked as read ✓'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      final apiService = ApiService();
      await apiService.init();
      await apiService.markAllAsRead('user', userId!);
      print("✅ API mark all read called");
    } catch (e) {
      print('⚠️ API failed, but local read status kept');
    }
  }

  void _handleBadgeTap() {
    final unreadCount = notifications.where((n) => n["read"] != true).length;
    if (unreadCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No unread notifications'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    _markAllAsRead();
  }

  // ==================== SOCKET LISTENER ====================
  
  void _setupSocketListener() {
    final socketService = SocketService();
    
    if (userId != null && userId!.isNotEmpty) {
      socketService.joinUserRoom(userId!);
      print("✅ Joined user room: $userId");
    }
    
    final createdCallback = (data) {
      print("📨 NOTIFICATION_CREATED received: $data");
      _handleNewNotification(data);
    };
    _listenerCallbacks.add(createdCallback);
    socketService.addListener(['NOTIFICATION_CREATED'], createdCallback);
    
    final readCallback = (data) {
      print("📨 NOTIFICATION_READ received: $data");
      _handleNotificationRead(data);
    };
    _listenerCallbacks.add(readCallback);
    socketService.addListener(['NOTIFICATION_READ'], readCallback);
    
    final deletedCallback = (data) {
      print("📨 NOTIFICATION_DELETED received: $data");
      _handleNotificationDeleted(data);
    };
    _listenerCallbacks.add(deletedCallback);
    socketService.addListener(['NOTIFICATION_DELETED'], deletedCallback);
    
    print("✅ Socket listeners registered with SocketService");
  }

  void _handleNewNotification(dynamic data) async {
    print("📨 New notification: $data");
    
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
    print("📖 Notification read: $data");
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
    print("🗑️ Notification deleted: $data");
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

  // ==================== FILTERS ====================
  
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

  // ==================== BUILD ====================
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final unreadCount = notifications.where((n) => n["read"] != true).length;
    final readCount = notifications.where((n) => n["read"] == true).length;

    // ✅ FIX: If user is not logged in, return full Scaffold
    if (userId == null || userId!.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFECFDF5),
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text(
            "Notifications", 
            style: TextStyle(color: Colors.white)
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text("Please login to view notifications"),
            ],
          ),
        ),
      );
    }

    // ✅ FIX: Main Scaffold with proper structure
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Notifications", 
          style: TextStyle(color: Colors.white)
        ),
        centerTitle: true,
        actions: [
          // Optional: Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
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
          ? const Center(child: CircularProgressIndicator())
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
                    padding: EdgeInsets.all(screenWidth * 0.04),
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
                              }
                            ),
                            const SizedBox(width: 10),
                            _buildFilterChip(
                              "Read ($readCount)", 
                              showRead, 
                              () {
                                setState(() {
                                  showRead = !showRead;
                                  showUnread = false;
                                  _updateFilteredList();
                                });
                              }
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _handleBadgeTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 8
                            ),
                            decoration: BoxDecoration(
                              color: unreadCount > 0
                                  ? Colors.red
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.notifications_active,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  errorMessage ?? "No notifications",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_totalCount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Total: $_totalCount notifications',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount:
                                filteredList.length + (_hasMorePages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredList.length &&
                                  _hasMorePages) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 8),
                                        Text(
                                          'Loading more...',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final n = filteredList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12, 
                                  vertical: 4
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: n["read"] == true
                                        ? Colors.grey[300]
                                        : Colors.green[100],
                                    child: Icon(
                                      n["read"] == true
                                          ? Icons.notifications_none
                                          : Icons.notifications_active,
                                      color: n["read"] == true
                                          ? Colors.grey
                                          : Colors.green,
                                    ),
                                  ),
                                  title: Text(
                                    n["message"] ?? "No message",
                                    style: TextStyle(
                                      fontWeight: n["read"] == true
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle:
                                      Text(_getRelativeTime(n["createdAt"])),
                                  trailing: n["read"] == true
                                      ? null
                                      : Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                  onTap: () {
                                    if (n["read"] != true) {
                                      _markAsRead(n["_id"].toString());
                                    } else {
                                      _navigateToNotificationDetails(n);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  
                  // Footer
                  if (_totalCount > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Showing ${notifications.length} of $_totalCount notifications',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.green[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.green[800],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}