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
    _setup();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    if (socket != null) {
      socket!.disconnect();
      socket!.dispose();
    }
    super.dispose();
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
      await _initializeNotifications();
      await _fetchNotifications();
      _setupSocketListener();
    } else {
      setState(() => isLoading = false);
    }
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

  void _updateBottomNavBadge(int count) {
    final bottomNavState = context.findAncestorStateOfType<BottomNavState>();
    if (bottomNavState != null) {
      bottomNavState.updateNotificationCount(count);
    } else {
      print('⚠️ Could not find BottomNavState');
    }
  }

  // ✅ FIXED: _fetchNotifications method
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
      });
    } else {
      if (_isLoadingMore || !_hasMorePages) return;
      setState(() => _isLoadingMore = true);
    }
    
    try {
      final apiService = ApiService();
      
      // ✅ Use getNotificationsByRole (this works!)
      final response = await apiService.getNotificationsByRole(
        'user', 
        userId!, 
        page: _currentPage,
        limit: 10,
      );
      
      print("📡 Response Status: ${response.statusCode}");
      
      List<dynamic> notificationList = [];
      int totalPages = 1;
      
      if (response.data['success'] == true) {
        notificationList = response.data['data'] ?? [];
        
        final pagination = response.data['pagination'];
        if (pagination != null) {
          totalPages = pagination['totalPages'] ?? 1;
          _totalPages = totalPages;
          _hasMorePages = _currentPage < totalPages;
        }
      }
      
      print("📦 Total notifications: ${notificationList.length}");
      print("📄 Page $_currentPage of $_totalPages");
      
      // ✅ Get read status from userReadStatus
      final myNotifications = notificationList.map((n) {
        final notificationId = n['id'].toString();
        
        // Get read status from backend
        final userReadStatus = n['userReadStatus'] as Map? ?? {};
        final isRead = userReadStatus[userId] == true;       
        print("🔍 Notification ${n['id']}: userReadStatus[$userId] = ${userReadStatus[userId]}, isRead = $isRead");
        return {
          "_id": notificationId,
          "id": n['id'],
          "message": n['message'] ?? "No message",
          "createdAt": n['createdAt'] ?? DateTime.now().toIso8601String(),
          "read": isRead,
        };
      }).toList();
      
      print("✅ Notifications for user: ${myNotifications.length}");
      
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
        });
        
        // Update badge count
        final unreadCount = notifications.where((n) => n["read"] != true).length;
        _updateBottomNavBadge(unreadCount);
      }
      
    } catch (e) {
      print("❌ Error: $e");
      if (mounted) {
        setState(() {
          errorMessage = "Failed to load notifications";
          _isLoadingMore = false;
        });
      }
    } finally {
      if (!isLoadMore && mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ✅ FIXED: _markAsRead with role parameter
  Future<void> _markAsRead(String notificationId) async {
    if (userId == null) return;
    
    try {
      final apiService = ApiService();
      
      // ✅ Add 'user' as role parameter
      final response = await apiService.markNotificationAsRead('user', userId!, notificationId);
      print("✅ Mark as read: ${response.statusCode}");
      print("📦 Response: ${response.data}");
      if (mounted) {
        setState(() {
          final index = notifications.indexWhere((n) => n["_id"] == notificationId);
          if (index != -1) {
            notifications[index]["read"] = true;
            _updateFilteredList();
          }
        });
        
        final remainingUnread = notifications.where((n) => n["read"] != true).length;
        _updateBottomNavBadge(remainingUnread);
        
        final notification = notifications.firstWhere(
          (n) => n["_id"] == notificationId,
          orElse: () => {},
        );
        _navigateToNotificationDetails(notification);
        
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Marked as read'), duration: Duration(seconds: 1)),
        // );
      }
      
    } catch (e) {
      print("❌ Error marking as read: $e");
     _markAsReadLocally(notificationId);
    }
  }

  // Local fallback method
  void _markAsReadLocally(String notificationId) {
    setState(() {
      final index = notifications.indexWhere((n) => n["_id"] == notificationId);
      if (index != -1) {
        notifications[index]["read"] = true;
        _updateFilteredList();
      }
    });
    final remainingUnread = notifications.where((n) => n["read"] != true).length;
    _updateBottomNavBadge(remainingUnread);
    
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Marked as read (offline)'), duration: Duration(seconds: 1)),
    // );
  }

  // Load more notifications
  Future<void> _loadMoreNotifications() async {
    if (!_hasMorePages || _isLoadingMore) return;
    _currentPage++;
    await _fetchNotifications(isLoadMore: true);
  }

  // ✅ FIXED: _markAllAsRead with role parameter
  Future<void> _markAllAsRead() async {
    if (userId == null) return;
    
    try {
      final apiService = ApiService();
      
      // ✅ Add 'user' as role parameter
      final response = await apiService.markAllAsRead('user', userId!);
      print("📡 Mark all read: ${response.statusCode}");
      print("📦 Message: ${response.data['message']}");

      if (mounted) {
        setState(() {
          for (var notification in notifications) {
            notification["read"] = true;
          }
          _updateFilteredList();
        });
        
        _updateBottomNavBadge(0);
        
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('All marked as read'), duration: Duration(seconds: 1)),
        // );
      }
      
    } catch (e) {
      print("❌ Error marking all as read: $e");
      // Local fallback
      setState(() {
        for (var notification in notifications) {
          notification["read"] = true;
        }
        _updateFilteredList();
      });
      _updateBottomNavBadge(0);
    //    ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('All marked as read'), 
    //     duration: Duration(seconds: 1),
    //     backgroundColor: const Color.fromARGB(255, 59, 46, 235),
    //   ),
    // );
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

  void _setupSocketListener() {
    try {
      socket = IO.io('https://www.zorrowtek.in', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
      });

      socket!.on('connect', (_) {
        print("✅ Socket connected");
        if (userId != null) {
          socket!.emit('joinUserRoom', userId);
        }
      });

      socket!.on('pushNotification', (data) async {
        print("📨 New notification: $data");
        await _fetchNotifications();
        _showLocalNotification(data);
      });

      socket!.connect();
    } catch (e) {
      print("❌ Socket error: $e");
    }
  }

  Future<void> _showLocalNotification(Map<String, dynamic> data) async {
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
    );
  }

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
          title: Text("Notifications", style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: Center(
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
        title: Text("Notifications", style: TextStyle(color: Colors.white)),
        centerTitle: true,    
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetchNotifications(),
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
                        if (notifications.isNotEmpty && unreadCount > 0)
                          TextButton(
                            onPressed: _markAllAsRead,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              "Mark All Read",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredList.isEmpty
                        ? Center(
                            child: Text(errorMessage ?? "No notifications"),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: filteredList.length + (_hasMorePages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredList.length && _hasMorePages) {
                                return Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              
                              final n = filteredList[index];
                              return Card(
                                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                                          decoration: BoxDecoration(
                                            color: Colors.red,
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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