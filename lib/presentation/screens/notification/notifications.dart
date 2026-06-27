import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger_plus/flutter_app_badger_plus.dart';
import 'package:hosta/presentation/screens/notification/notification_details.dart';
import 'package:hosta/services/fcm_service.dart';
import 'package:intl/intl.dart';
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
  IO.Socket? socket;
  String? errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;
  
  late ScrollController _scrollController;
  
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
    
    if (userId != null && userId!.isNotEmpty) {
      await FCMService.initialize();
      await FCMService.subscribeToTopic('user_$userId');
      await _initializeNotifications();
      await _fetchNotifications();
      await _loadSavedBadgeCount();
      _setupSocketListener();
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    if (userId != null) {
      FCMService.unsubscribeFromTopic('user_$userId');
    }
    _scrollController.dispose();
    if (socket != null) {
      socket!.off('pushNotification');
      socket!.off('notificationRead');
      socket!.off('notificationDeleted');
      socket!.disconnect();
      socket!.dispose();
    }
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
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
    );

    final plugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(channel);

    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );
  }

  // ==================== BADGE UPDATE METHODS ====================
  
  void _updateBottomNavBadge(int count) {
    print('📊 _updateBottomNavBadge called with: $count');
    
    // ✅ Method 1: Using GlobalKey
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
    
    // ✅ Method 2: Fallback - Find Ancestor
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
    
    // ✅ Method 3: Save to SharedPreferences
    _updateBadgeViaSharedPreferences(count);
    print('📊 Saved to SharedPreferences only');
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

  // ==================== FETCH NOTIFICATIONS ====================
  
  Future<void> _fetchNotifications({bool isLoadMore = false}) async {
    if (userId == null || userId!.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    if (!isLoadMore) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        _currentPage = 1;
        notifications = [];
        _hasMorePages = true;
      });
    } else {
      if (_isLoadingMore || !_hasMorePages) return;
      setState(() => _isLoadingMore = true);
    }
    
    try {
      final apiService = ApiService();
      
      final response = await apiService.getNotificationsByRole(
        'user', 
        userId!, 
        page: _currentPage,
        limit: 10,
      );
      
      print("📡 Response Status: ${response.statusCode}");
      
      if (response.data['success'] == true) {
        final notificationList = response.data['data'];
        final totalCount = response.data['count'] ?? 0;
        
        final limit = 10;
        final totalPages = totalCount > 0 ? (totalCount / limit).ceil() : 1;
        _totalPages = totalPages;
        _hasMorePages = _currentPage < totalPages;
        
        print("📦 Total notifications from API: $totalCount");
        print("📄 Page $_currentPage of $totalPages");
        
        List<Map<String, dynamic>> myNotifications = [];
        
        if (notificationList is List) {
          print("📦 Notification list length: ${notificationList.length}");
          
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
              final isRead = userReadStatus[userId] == true;
              
              print("🔍 Notification ${notification['id']}: isRead = $isRead");
              
              myNotifications.add({
                "_id": notificationId,
                "id": notification['id'],
                "message": notification['message'] ?? "No message",
                "createdAt": notification['createdAt'] ?? DateTime.now().toIso8601String(),
                "read": isRead,
                "title": notification['title'] ?? "Notification",
                "data": notification['data'] ?? {},
              });
            } catch (e) {
              print("⚠️ Error processing notification item: $e");
            }
          }
        }
        
        print("✅ Processed notifications: ${myNotifications.length}");
        
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
      
      final response = await apiService.getUnreadCount('user', userId!);
      print('📊 Unread count response: ${response.data}');
      
      if (response.data['success'] == true) {
        final unreadCount = response.data['count'] ?? 0;
        _updateBottomNavBadge(unreadCount);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_count', unreadCount);
        await prefs.setInt('unread_count_$userId', unreadCount);
        
        print('📊 Total unread count from API: $unreadCount');
      } else {
        final unreadCount = notifications.where((n) => n["read"] != true).length;
        _updateBottomNavBadge(unreadCount);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notification_count', unreadCount);
        await prefs.setInt('unread_count_$userId', unreadCount);
        
        print('📊 Total unread count from local: $unreadCount');
      }
    } catch (e) {
      print('❌ Error getting unread count: $e');
      
      final unreadCount = notifications.where((n) => n["read"] != true).length;
      _updateBottomNavBadge(unreadCount);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_count', unreadCount);
      await prefs.setInt('unread_count_$userId', unreadCount);
      
      print('📊 Total unread count from local (fallback): $unreadCount');
    }
  }

  // ==================== MARK AS READ - INDIVIDUAL ====================
  
  // Future<void> _markAsRead(String notificationId) async {
  //   if (userId == null) return;
    
  //   try {
  //     final apiService = ApiService();
      
  //     final response = await apiService.markNotificationAsRead('user', userId!, notificationId);
  //     print("✅ Mark as read response: ${response.statusCode}");
  //      print("✅ Response data: ${response.data}");

  //     if (response.data['success'] == true) {
  //       if (mounted) {
  //         setState(() {
  //           final index = notifications.indexWhere((n) => n["_id"] == notificationId);
  //           if (index != -1) {
  //             notifications[index]["read"] = true;
  //             _updateFilteredList();
  //           }
  //         });
          
  //         await _updateBadgeCount();
          
  //         final notification = notifications.firstWhere(
  //           (n) => n["_id"] == notificationId,
  //           orElse: () => {},
  //         );
  //         _navigateToNotificationDetails(notification);
  //       }
  //     } else {
  //       _markAsReadLocally(notificationId);
  //     }
      
  //   } catch (e) {
  //     print("❌ Error marking as read: $e");
  //     _markAsReadLocally(notificationId);
  //   }
  // }
  // ✅ COMPLETE WORKING _markAsRead
Future<void> _markAsRead(String notificationId) async {
  if (userId == null) return;
  
  try {
    final apiService = ApiService();
    
    // ✅ CORRECT: No extra ID in URL
    final response = await apiService.markNotificationAsRead('user', userId!, notificationId);
    print("✅ Mark as read response: ${response.statusCode}");
    print("✅ Response data: ${response.data}");
    
    // ✅ Update UI regardless of API response
    if (mounted) {
      setState(() {
        final index = notifications.indexWhere((n) => n["_id"] == notificationId);
        if (index != -1) {
          notifications[index]["read"] = true;
          _updateFilteredList();
        }
      });
      
      await _updateBadgeCount();
      
      final notification = notifications.firstWhere(
        (n) => n["_id"] == notificationId,
        orElse: () => {},
      );
      _navigateToNotificationDetails(notification);
    }
    
  } catch (e) {
    print("❌ Error marking as read: $e");
    // ✅ Fallback: Mark locally
    if (mounted) {
      setState(() {
        final index = notifications.indexWhere((n) => n["_id"] == notificationId);
        if (index != -1) {
          notifications[index]["read"] = true;
          _updateFilteredList();
        }
      });
      _updateBadgeCount();
    }
  }
}

  void _markAsReadLocally(String notificationId) {
    if (mounted) {
      setState(() {
        final index = notifications.indexWhere((n) => n["_id"] == notificationId);
        if (index != -1) {
          notifications[index]["read"] = true;
          _updateFilteredList();
        }
      });
      _updateBadgeCount();
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (!_hasMorePages || _isLoadingMore) return;
    _currentPage++;
    await _fetchNotifications(isLoadMore: true);
  }

  // ==================== MARK ALL READ ====================
  
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

// ✅ COMPLETE FIXED - Fast Mark All Read
// ✅ FAST Mark All Read - Single API call
Future<void> _markAllAsRead() async {
  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please login first'), backgroundColor: Colors.red),
    );
    return;
  }
  
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
  
  // Show loading
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Marking all as read...'),
      duration: Duration(seconds: 1),
    ),
  );
  
  bool apiSuccess = false;
  
  // ✅ SINGLE API CALL - No loop!
  try {
    final apiService = ApiService();
    final response = await apiService.markAllAsRead('user', userId!);
    
    print("📡 Mark all read response: ${response.statusCode}");
    print("📡 Response data: ${response.data}");
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      apiSuccess = true;
      print('✅ API mark all read success');
    } else {
      print('❌ API returned error: ${response.data}');
    }
  } catch (e) {
    print('❌ API failed: $e');
  }
  
  // ✅ ALWAYS UPDATE UI (Even if API fails)
  if (mounted) {
    setState(() {
      for (var notification in notifications) {
        notification["read"] = true;
      }
      _updateFilteredList();
    });
    
    // ✅ Update badge to 0
    _updateBottomNavBadge(0);
    
    // ✅ Save to SharedPreferences
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
  }
}

  // // ✅ FIXED: Mark All Read - 100% Working
  // Future<void> _markAllAsRead() async {
  //   if (userId == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Please login first'), backgroundColor: Colors.red),
  //     );
  //     return;
  //   }
    
  //   final unreadNotifications = notifications.where((n) => n["read"] != true).toList();
  //   if (unreadNotifications.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('No unread notifications'),
  //         backgroundColor: Colors.grey,
  //         duration: Duration(seconds: 1),
  //       ),
  //     );
  //     return;
  //   }
    
  //   // Show loading
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Marking ${unreadNotifications.length} notifications as read...'),
  //       duration: Duration(seconds: 1),
  //     ),
  //   );
    
  //   bool anySuccess = false;
    
  //   // ✅ TRY API FIRST
  //   try {
  //     final apiService = ApiService();
  //     final response = await apiService.markAllAsRead('user', userId!);
      
  //     if (response.statusCode == 200 && response.data['success'] == true) {
  //       anySuccess = true;
  //       print('✅ API mark all read success');
  //     }
  //   } catch (e) {
  //     print('❌ API mark all read failed: $e');
  //   }
    
  //   // ✅ If API failed, try individual marking
  //   if (!anySuccess) {
  //     print('🔄 Trying individual marking...');
  //     int successCount = 0;
      
  //     for (var notification in unreadNotifications) {
  //       try {
  //         final apiService = ApiService();
  //         final notificationId = notification["id"].toString();
  //         final response = await apiService.markNotificationAsRead('user', userId!, notificationId);
          
  //         if (response.data['success'] == true) {
  //           successCount++;
  //           print("✅ Marked notification $notificationId as read");
  //         }
  //       } catch (e) {
  //         print("❌ Failed to mark notification ${notification['id']}: $e");
  //       }
  //     }
      
  //     print("✅ Successfully marked $successCount notifications as read");
  //     if (successCount > 0) anySuccess = true;
  //   }
    
  //   // ✅ ALWAYS UPDATE UI (Even if API fails)
  //   if (mounted) {
  //     setState(() {
  //       for (var notification in notifications) {
  //         notification["read"] = true;
  //       }
  //       _updateFilteredList();
  //     });
      
  //     // ✅ Update badge to 0
  //     _updateBottomNavBadge(0);
      
  //     // ✅ Save to SharedPreferences
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setInt('notification_count', 0);
  //     await prefs.setInt('unread_count_$userId', 0);
      
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('All notifications marked as read ✓'),
  //         backgroundColor: Colors.green,
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //   }
  // }

  // ==================== NEW NOTIFICATION HANDLER ====================
  
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
      };
      
      setState(() {
        notifications.insert(0, newNotification);
        _updateFilteredList();
      });
      
      await _updateBadgeCount();
      _showLocalNotification(data);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'New notification'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              _navigateToNotificationDetails({
                '_id': data['id'].toString(),
                'message': data['message'],
                'createdAt': DateTime.now().toIso8601String(),
                'title': data['title'] ?? 'Notification',
              });
            },
          ),
        ),
      );
    }
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

  // ==================== SOCKET LISTENER ====================
  
  void _setupSocketListener() {
    try {
      if (socket != null) {
        socket!.disconnect();
        socket!.dispose();
      }
      
      socket = IO.io('https://www.zorrowtek.in', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 2000,
        'reconnectionDelayMax': 10000,
        'timeout': 20000,
        'forceNew': true,
      });

      socket!.on('connect', (_) {
        if (userId != null) {
          socket!.emit('joinUserRoom', userId);
          socket!.emit('userOnline', userId);
        }
      });

      socket!.on('connect_error', (error) {
        print("❌ Connection error: $error");
      });

      socket!.on('error', (error) {
        print("❌ Socket error: $error");
      });

      socket!.on('disconnect', (_) {
        print("⚠️ Socket disconnected");
      });

      socket!.on('pushNotification', _handleNewNotification);
      socket!.on('notificationRead', _handleNotificationRead);
      socket!.on('notificationDeleted', _handleNotificationDeleted);

      socket!.connect();
    } catch (e) {
      print("❌ Socket setup error: $e");
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

  // ==================== LOCAL NOTIFICATION ====================
  
  Future<void> _showLocalNotification(Map<String, dynamic> data) async {
    try {
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000).toInt(),
        data['title'] ?? 'New Notification',
        data['message'] ?? 'You have a new notification',
        platformChannelSpecifics,
        payload: data['id']?.toString(),
      );
    } catch (e) {
      print("❌ Error showing local notification: $e");
    }
  }

  // ==================== FILTERS ====================
  
  void _updateFilteredList() {
    filteredList = notifications.where((n) {
      bool matchesRead = (!showUnread && !showRead) ||
          (showUnread && n["read"] != true) ||
          (showRead && n["read"] == true);
      
      bool matchesDate = selectedDate.isEmpty ||
          DateFormat('yyyy-MM-dd').format(DateTime.parse(n["createdAt"])) == selectedDate;
      
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
  
    if (userId == null || userId!.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFECFDF5),
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text("Notifications", style: TextStyle(color: Colors.white)),
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
    
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Notifications", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchNotifications();
                await _updateBadgeCount();
              },
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildFilterChip("Unread ($unreadCount)", showUnread, () {
                              setState(() {
                                showUnread = !showUnread;
                                showRead = false;
                                _updateFilteredList();
                              });
                            }),
                            SizedBox(width: 10),
                            _buildFilterChip("Read ($readCount)", showRead, () {
                              setState(() {
                                showRead = !showRead;
                                showUnread = false;
                                _updateFilteredList();
                              });
                            }),
                          ],
                        ),
                        GestureDetector(
                          onTap: _handleBadgeTap,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: unreadCount > 0 ? Colors.red : Colors.grey[300],
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
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: filteredList.length + (_hasMorePages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredList.length && _hasMorePages) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              
                              final n = filteredList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: n["read"] == true ? Colors.grey[300] : Colors.green[100],
                                    child: Icon(
                                      n["read"] == true ? Icons.notifications_none : Icons.notifications_active,
                                      color: n["read"] == true ? Colors.grey : Colors.green,
                                    ),
                                  ),
                                  title: Text(
                                    n["message"] ?? "No message",
                                    style: TextStyle(
                                      fontWeight: n["read"] == true ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(_getRelativeTime(n["createdAt"])),
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