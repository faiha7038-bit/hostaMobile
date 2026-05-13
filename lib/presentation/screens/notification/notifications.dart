import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? userId;
  String selectedDate = "";
  bool showUnread = false;
  bool showRead = false;
  IO.Socket? socket;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
   // _initializeNotifications();
    _loadUserIdAndFetchNotifications();
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );
  }

  Future<void> _showLocalNotification(
    Map<String, dynamic> notificationData,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'your_channel_id',
          'Your Channel Name',
          channelDescription: 'Your Channel Description',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      notificationData['title'] ?? 'New Notification',
      notificationData['message'] ?? 'You have a new notification',
      platformChannelSpecifics,
      payload: notificationData.toString(),
    );
  }
Future<void> _loadUserIdAndFetchNotifications() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('userId');

    if (mounted) {
      setState(() {
        userId = storedUserId;
      });
    }

    if (userId != null && userId!.isNotEmpty) {
      // ✅ Move initialization HERE (only when user exists)
      await _initializeNotifications();
      
      await _fetchNotifications();
      _setupSocketListener();
    } else {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  } catch (e) {
    print("❌ Error loading user ID: $e");
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}

  Future<void> _fetchNotifications() async {
    if (userId == null || userId!.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);
    try {
      final unreadResp = await ApiService().getAllNotificationUnRead(userId!);
      final readResp = await ApiService().getAllNotificationRead(userId!);

      List<dynamic> unreadList = [];
      List<dynamic> readList = [];

      if (unreadResp.data is List) {
        unreadList = unreadResp.data;
      } else if (unreadResp.data?['notifications'] is List) {
        unreadList = unreadResp.data!['notifications'];
      }

      if (readResp.data is List) {
        readList = readResp.data;
      } else if (readResp.data?['notifications'] is List) {
        readList = readResp.data!['notifications'];
      }

      final unread = List<Map<String, dynamic>>.from(
        unreadList,
      ).map((n) => {...n, "read": false}).toList();

      final read = List<Map<String, dynamic>>.from(
        readList,
      ).map((n) => {...n, "read": true}).toList();

      notifications = [...unread, ...read];

      notifications.sort(
        (a, b) => DateTime.parse(
          b["createdAt"],
        ).compareTo(DateTime.parse(a["createdAt"])),
      );

      selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    } catch (e) {
      print("❌ Error fetching notifications: $e");
      notifications = [];
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _setupSocketListener() {
    try {
      const String serverUrl = 'https://www.zorrowtek.in';

      socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
      });

      socket!.on('connect', (_) {
        print("✅ Connected to server via Socket.IO");
        if (userId != null) {
          socket!.emit('joinUserRoom', userId);
        }
      });

      socket!.on('disconnect', (_) {
        print("🔌 Disconnected from server");
      });

      socket!.on('error', (error) {
        print('⚠️ Socket error: $error');
      });

      socket!.on('pushNotification', (data) {
        print('📡 Socket notification received: $data');
        final notificationUserId = data['userId']?.toString();

        if (notificationUserId == userId) {
          print('📱 Processing socket notification for current user');
          _showSocketNotificationPopup(data);
          _handleSocketNotification(data);
        } else {
          print('🚫 This socket notification is for another user');
        }
      });

      socket!.connect();
      print('🔌 Socket.IO connection initiated');
    } catch (e) {
      print('❌ Error setting up socket: $e');
    }
  }

  void _showSocketNotificationPopup(Map<String, dynamic> notificationData) {
    final title = notificationData['title']?.toString() ?? 'New Notification';
    final message =
        notificationData['message']?.toString() ??
        'You have a new notification';

    _showLocalNotification(notificationData);

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _handleSocketNotification(Map<String, dynamic> notificationData) {
    _fetchNotifications();
  }

  Future<void> _markNotificationRead(String id) async {
    try {
      await ApiService().aReadNotification(id);
      if (mounted) {
        setState(() {
          final index = notifications.indexWhere((n) => n["_id"] == id);
          if (index != -1) notifications[index]["read"] = true;
        });
      }
    } catch (e) {
      print("❌ Error marking notification read: $e");
    }
  }

  Future<void> _markAllRead() async {
    if (userId == null || userId!.isEmpty) return;

    try {
      await ApiService().allReadNotifications(userId!);
      if (mounted) {
        setState(() {
          for (var n in notifications) {
            n["read"] = true;
          }
        });
      }
    } catch (e) {
      print("❌ Error marking all notifications read: $e");
    }
  }

  String _getRelativeTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years ${years == 1 ? 'year' : 'years'} ago';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    
    // Responsive sizing based on screen width
    final double horizontalPadding = screenWidth * 0.04;
    final double verticalPadding = screenHeight * 0.01;
    final double chipFontSize = screenWidth * 0.035;
    final double chipPaddingHorizontal = screenWidth * 0.035;
    final double chipPaddingVertical = screenWidth * 0.02;
    final double dateFilterFontSize = screenWidth * 0.032;
    final double iconSize = screenWidth * 0.05;

    if (userId == null || userId!.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFECFDF5),
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: Text(
            "Notifications",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: screenWidth * 0.05,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off,
                  size: screenWidth * 0.15,
                  color: Colors.grey,
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  "Please login to view notifications",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredList = notifications.where((n) {
      bool matchesRead =
          (!showUnread && !showRead) ||
          (showUnread && !n["read"]) ||
          (showRead && n["read"]);

      bool matchesDate =
          selectedDate.isEmpty ||
          DateFormat('yyyy-MM-dd').format(DateTime.parse(n["createdAt"])) ==
              selectedDate;

      return matchesRead && matchesDate;
    }).toList();

    final unreadCount = notifications.where((n) => !n["read"]).length;
    final readCount = notifications.where((n) => n["read"]).length;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
        actions: [
          if (notifications.isNotEmpty && unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                "Mark All Read",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ===== FILTER SECTION WITH RESPONSIVE SIZING =====
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    children: [
                      // Unread/Read Filter Chips
                      Row(
                        children: [
                          _buildResponsiveFilterChip(
                            label: "Unread ($unreadCount)",
                            selected: showUnread,
                            onTap: () {
                              setState(() {
                                showUnread = !showUnread;
                                showRead = false;
                              });
                            },
                            screenWidth: screenWidth,
                            chipFontSize: chipFontSize,
                            chipPaddingHorizontal: chipPaddingHorizontal,
                            chipPaddingVertical: chipPaddingVertical,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          _buildResponsiveFilterChip(
                            label: "Read ($readCount)",
                            selected: showRead,
                            onTap: () {
                              setState(() {
                                showRead = !showRead;
                                showUnread = false;
                              });
                            },
                            screenWidth: screenWidth,
                            chipFontSize: chipFontSize,
                            chipPaddingHorizontal: chipPaddingHorizontal,
                            chipPaddingVertical: chipPaddingVertical,
                          ),
                        ],
                      ),
                      
                      SizedBox(height: screenHeight * 0.015),

                      // Date Filter Container
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.012,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.green,
                              size: iconSize,
                            ),
                            SizedBox(width: screenWidth * 0.025),
                            Expanded(
                              child: Text(
                                selectedDate.isEmpty ? "Select date" : selectedDate,
                                style: TextStyle(
                                  fontSize: dateFilterFontSize,
                                  color: selectedDate.isEmpty
                                      ? Colors.grey
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (selectedDate.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedDate = "";
                                    showRead = false;
                                    showUnread = false;
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: screenWidth * 0.045,
                                  color: Colors.grey,
                                ),
                              ),
                            SizedBox(width: screenWidth * 0.02),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.03,
                                  vertical: screenHeight * 0.008,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                ),
                                minimumSize: Size(screenWidth * 0.12, 0),
                              ),
                              onPressed: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate.isEmpty
                                      ? DateTime.now()
                                      : DateTime.parse(selectedDate),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedDate = DateFormat('yyyy-MM-dd').format(picked);
                                  });
                                }
                              },
                              child: Text(
                                "Filter",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Divider(height: screenHeight * 0.001),
                
                // Notification List
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.08),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: screenWidth * 0.12,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Text(
                                  "No notifications found",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.02,
                            vertical: screenHeight * 0.01,
                          ),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final n = filteredList[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenHeight * 0.005,
                              ),
                              elevation: isSmallScreen ? 1 : 2,
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.01,
                                ),
                                leading: Container(
                                  width: screenWidth * 0.1,
                                  height: screenWidth * 0.1,
                                  decoration: BoxDecoration(
                                    color: n["read"]
                                        ? Colors.grey.shade300
                                        : Colors.green.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    n["read"]
                                        ? Icons.notifications_none
                                        : Icons.notifications_active,
                                    color: n["read"] ? Colors.grey : Colors.green,
                                    size: screenWidth * 0.055,
                                  ),
                                ),
                                title: Text(
                                  n["message"] ?? "No message",
                                  style: TextStyle(
                                    fontWeight: n["read"] ? FontWeight.normal : FontWeight.bold,
                                    color: n["read"] ? Colors.grey.shade700 : Colors.black87,
                                    fontSize: screenWidth * 0.04,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _getRelativeTime(n["createdAt"]),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                                trailing: n["read"]
                                    ? null
                                    : Icon(
                                        Icons.circle,
                                        color: Colors.red,
                                        size: screenWidth * 0.025,
                                      ),
                                onTap: () {
                                  if (!n["read"]) {
                                    _markNotificationRead(n["_id"]);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Responsive Filter Chip Widget
  Widget _buildResponsiveFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required double screenWidth,
    required double chipFontSize,
    required double chipPaddingHorizontal,
    required double chipPaddingVertical,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: chipPaddingHorizontal,
          vertical: chipPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.green.shade50,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          border: selected 
              ? null 
              : Border.all(color: Colors.green.shade200, width: 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Padding(
                padding: EdgeInsets.only(right: screenWidth * 0.015),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: screenWidth * 0.04,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: chipFontSize,
                color: selected ? Colors.white : Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}