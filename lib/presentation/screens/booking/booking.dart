// import 'package:flutter/material.dart';
// import 'package:hosta/common/top_snackbar.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import '../services/api_service.dart';

// class Booking extends StatefulWidget {
//   const Booking({super.key});

//   @override
//   State<Booking> createState() => _BookingState();
// }

// class _BookingState extends State<Booking> {
//   String selectedFilter = "All";
//   String searchQuery = "";
//   DateTime? selectedDate;
//   bool isLoading = true;
//   String? userId;
//   IO.Socket? socket;

//   final TextEditingController _searchController = TextEditingController();
//   List<Map<String, dynamic>> bookings = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadUserIdAndFetchBookings();
//     _setupSocketListener(); // Initialize socket when widget loads
//   }

//   @override
//   void dispose() {
//     // Clean up socket connection when widget is disposed
//     socket?.disconnect();
//     socket?.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   // Load user ID first, then fetch bookings
//   Future<void> _loadUserIdAndFetchBookings() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final storedUserId = prefs.getString('userId');
      
//       if (mounted) {
//         setState(() {
//           userId = storedUserId;
//         });
//       }
      
//       print("📱 Loaded user ID for bookings: $userId");
      
//       if (userId != null && userId!.isNotEmpty) {
//         await _fetchBookings();
//       } else {
//         if (mounted) {
//           setState(() => isLoading = false);
//         }
//         print("❌ No user ID found for bookings");
//       }
//     } catch (e) {
//       print("❌ Error loading user ID: $e");
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//   }

//   Future<void> _fetchBookings() async {
//     if (userId == null || userId!.isEmpty) {
//       setState(() => isLoading = false);
//       return;
//     }

//     setState(() => isLoading = true);
//     try {
//       final response = await ApiService().getAllBookings(userId!);
//       print("📋 Bookings API Response: ${response.data}");
      
//       // Handle different response structures
//       dynamic bookingsData;
//       if (response.data is Map && response.data.containsKey('data')) {
//         bookingsData = response.data['data'];
//       } else if (response.data is List) {
//         bookingsData = response.data;
//       } else {
//         bookingsData = [];
//       }

//       if (bookingsData is List) {
//         bookings = List<Map<String, dynamic>>.from(bookingsData.map((b) {
//           // Extract hospital data correctly - FIXED HERE
//           final hospitalData = b["hospitalId"] is Map ? b["hospitalId"] : {};
//           final hospitalName = hospitalData["name"] ?? "Unknown Hospital";
//           final hospitalType = hospitalData["type"] ?? "General";
//           final hospitalId = hospitalData["_id"] ?? b["hospitalId"] ?? "";

//           return {
//             "id": b["bookingId"] ?? b["_id"] ?? "",
//             "hospital_id": hospitalId,
//             "hospital": hospitalName, // ✅ FIXED: Now gets hospitalId.name
//             "type": hospitalType, // ✅ FIXED: Now gets hospitalId.type
//             "doctor": b["doctor_name"] ?? "Not specified",
//             "specialty": b["specialty"] ?? "General",
//             "date": _parseDate(b["booking_date"]),
//             "status": (b["status"] ?? "pending").toString().toLowerCase(),
//             "time": b["booking_time"] ?? "N/A",
//             "patient_name": b["patient_name"] ?? "",
//             "patient_phone": b["patient_phone"] ?? "",
//             "patient_place": b["patient_place"] ?? "",
//           };
//         }));
//       } else {
//         bookings = [];
//       }
      
//       print("✅ Loaded ${bookings.length} bookings");
//     } catch (e) {
//       print("❌ Error fetching bookings: $e");
//       bookings = [];
//     } finally {
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//   }

//   void _setupSocketListener() {
//     try {
//       // Replace with your backend URL
//       const String serverUrl = 'https://www.zorrowtek.in';
      
//       socket = IO.io(serverUrl, <String, dynamic>{
//         'transports': ['websocket', 'polling'],
//         'autoConnect': true,
//       });

//       socket!.on('connect', (_) {
//         print("✅ Connected to server via Socket.IO");
        
//         // Join user-specific room after connection
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

//       // Listen for new booking notifications
//       socket!.on('bookingCreated', (data) {
//         _handleSocketNotification(data, 'bookingCreated');
//       });

//       // Listen for booking update notifications
//       socket!.on('bookingUpdate', (data) {
//         print('📡 Booking update notification received: $data');
//         _handleSocketNotification(data, 'bookingUpdate');
//       });

//       socket!.connect();
//       print('🔌 Socket.IO connection initiated');

//     } catch (e) {
//       print('❌ Error setting up socket: $e');
//     }
//   }

//   void _handleSocketNotification(dynamic data, String eventType) {
//     if (!mounted) return;
    
//     try {
//       // Extract user ID from notification data
//       final notificationUserId = data['userId']?.toString();
//       final bookingId = data['bookingId']?.toString();
      
//       print('📱 Processing $eventType for user: $notificationUserId, booking: $bookingId');
      
//       // Check if the notification is for this user
//       if (notificationUserId == userId) {
//         print('🔄 Refreshing bookings due to socket notification');
       
        
//         // Refresh the bookings list
//         _fetchBookings();
//       } else {
//         print('🚫 This socket notification is for another user');
//       }
//     } catch (e) {
//       print('❌ Error handling socket notification: $e');
//     }
//   }

//   String _parseDate(dynamic date) {
//     try {
//       if (date == null) return "N/A";
//       return DateFormat('yyyy-MM-dd').format(DateTime.parse(date.toString()));
//     } catch (e) {
//       return "Invalid date";
//     }
//   }

//   // Format time to ensure consistent display
//   String _formatTime(dynamic time) {
//     try {
//       if (time == null || time == "N/A") return "N/A";
      
//       String timeStr = time.toString().trim();
      
//       // If time is already in a good format, return as is
//       if (timeStr.contains(':') && timeStr.length <= 5) {
//         return timeStr;
//       }
      
//       // Handle different time formats if needed
//       if (timeStr.contains('T')) {
//         // Handle ISO format
//         DateTime dateTime = DateTime.parse(timeStr);
//         return DateFormat('HH:mm').format(dateTime);
//       }
      
//       return timeStr;
//     } catch (e) {
//       return time?.toString() ?? "N/A";
//     }
//   }

//   List<Map<String, dynamic>> get filteredBookings {
//     return bookings.where((b) {
//       final matchesFilter =
//           selectedFilter == "All" || b["status"] == selectedFilter.toLowerCase();
//       final matchesSearch = b["hospital"]
//               .toString()
//               .toLowerCase()
//               .contains(searchQuery.toLowerCase()) ||
//           b["doctor"]
//               .toString()
//               .toLowerCase()
//               .contains(searchQuery.toLowerCase());
//       final matchesDate = selectedDate == null ||
//           b["date"] == DateFormat('yyyy-MM-dd').format(selectedDate!);
//       return matchesFilter && matchesSearch && matchesDate;
//     }).toList();
//   }

//   void _selectDate() async {
//     DateTime now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate ?? now,
//       firstDate: DateTime(now.year - 1),
//       lastDate: DateTime(now.year + 1),
//     );
//     if (picked != null && mounted) {
//       setState(() => selectedDate = picked);
//     }
//   }

//   Future<void> _cancelBooking(Map<String, dynamic> booking) async {
//     final bookingId = booking["id"].toString();
//     final hospitalId = booking["hospital_id"].toString();
    
//     if (bookingId.isEmpty || hospitalId.isEmpty) {
//       showTopSnackBar(context, "Invalid booking data", isError: true);
//       return;
//     }

//     try {
//       await ApiService().updateBooking(bookingId, hospitalId, {"status": "cancel"});
//       if (mounted) {
//         setState(() {
//           booking["status"] = "cancel";
//         });
//       }
//       showTopSnackBar(context, "Booking cancelled successfully");
//     } catch (e) {
//       print("❌ Error cancelling booking: $e");
//       showTopSnackBar(context, "Failed to cancel booking", isError: true);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Show message if no user ID
//     if (userId == null || userId!.isEmpty) {
//       return Scaffold(
//         backgroundColor: const Color(0xFFECFDF5),
//         appBar: AppBar(
//           backgroundColor: Colors.green,
//           title: const Text(
//             "My Bookings",
//             style: TextStyle(
//               fontWeight: FontWeight.bold, 
//               color: Colors.white,
//             ),
//           ),
//           centerTitle: true,
//         ),
//         body: const Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.person_off, size: 60, color: Colors.grey),
//               SizedBox(height: 16),
//               Text(
//                 "Please login to view your bookings",
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final bookingsToShow = filteredBookings;

//     return Scaffold(
//       backgroundColor: const Color(0xFFECFDF5),
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         title: const Text(
//           "My Bookings",
//           style: TextStyle(
//             fontWeight: FontWeight.bold, 
//             color: Colors.white,
//           ),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _fetchBookings,
//             tooltip: "Refresh bookings",
//           ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Search Bar
//                   TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: "Search by hospital or doctor",
//                       prefixIcon: const Icon(Icons.search),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onChanged: (value) => setState(() => searchQuery = value),
//                   ),
//                   const SizedBox(height: 12),

//                   // Date Filter
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         selectedDate == null
//                             ? "Filter by date"
//                             : "Date: ${DateFormat('dd MMM yyyy').format(selectedDate!)}",
//                         style: const TextStyle(fontWeight: FontWeight.w500),
//                       ),
//                       TextButton.icon(
//                         onPressed: _selectDate,
//                         icon: const Icon(Icons.calendar_today, size: 18),
//                         label: const Text("Select Date"),
//                       ),
//                     ],
//                   ),

//                   // Status Filter Chips
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Row(
//                       children: ["All", "Pending", "Accepted", "Declined", "Cancelled"]
//                           .map(
//                             (f) => Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 4),
//                               child: ChoiceChip(
//                                 label: Text(f),
//                                 selected: selectedFilter == f,
//                                 onSelected: (_) {
//                                   setState(() {
//                                     selectedFilter = f;
//                                     if (f == "All") {
//                                       selectedDate = null;
//                                       _searchController.clear();
//                                       searchQuery = "";
//                                     }
//                                   });
//                                 },
//                                 selectedColor: Colors.green,
//                                 labelStyle: TextStyle(
//                                   color: selectedFilter == f ? Colors.white : Colors.black,
//                                 ),
//                               ),
//                             ),
//                           )
//                           .toList(),
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Booking List
//                   Expanded(
//                     child: bookingsToShow.isEmpty
//                         ? const Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.event_busy, size: 60, color: Colors.grey),
//                                 SizedBox(height: 16),
//                                 Text(
//                                   "No bookings found",
//                                   style: TextStyle(
//                                       fontSize: 16,
//                                       color: Colors.grey,
//                                       fontWeight: FontWeight.w600),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : ListView.builder(
//                             itemCount: bookingsToShow.length,
//                             itemBuilder: (context, index) {
//                               final b = bookingsToShow[index];
//                               return Card(
//                                 shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12)),
//                                 margin: const EdgeInsets.symmetric(vertical: 8),
//                                 elevation: 3,
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(12),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           const Icon(Icons.local_hospital,
//                                               color: Colors.green),
//                                           const SizedBox(width: 8),
//                                           Expanded(
//                                             child: Text(
//                                               b["hospital"],
//                                               overflow: TextOverflow.ellipsis,
//                                               style: const TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 16),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 6),
//                                       Row(
//                                         children: [
//                                           const Icon(Icons.person,
//                                               color: Colors.blueAccent),
//                                           const SizedBox(width: 8),
//                                           Expanded(
//                                             child: Text(
//                                               "Doctor: ${b["doctor"]}",
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Row(
//                                         children: [
//                                           const Icon(Icons.medical_services,
//                                               color: Colors.orange),
//                                           const SizedBox(width: 8),
//                                           Expanded(
//                                             child: Text(
//                                               "Type: ${b["type"]}",
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Row(
//                                         children: [
//                                           const Icon(Icons.health_and_safety,
//                                               color: Colors.purple),
//                                           const SizedBox(width: 8),
//                                           Expanded(
//                                             child: Text(
//                                               "Specialty: ${b["specialty"]}",
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Row(
//                                         children: [
//                                           const Icon(Icons.calendar_today,
//                                               color: Colors.teal),
//                                           const SizedBox(width: 8),
//                                           Text("Date: ${b["date"]}"),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Row(
//                                         children: [
//                                           const Icon(Icons.access_time,
//                                               color: Colors.redAccent),
//                                           const SizedBox(width: 8),
//                                           Text("Time: ${_formatTime(b["time"])}"),
//                                         ],
//                                       ),
//                                       if (b["patient_name"]?.isNotEmpty == true) ...[
//                                         const SizedBox(height: 4),
//                                         Row(
//                                           children: [
//                                             const Icon(Icons.person_outline,
//                                                 color: Colors.brown),
//                                             const SizedBox(width: 8),
//                                             Expanded(
//                                               child: Text(
//                                                 "Patient: ${b["patient_name"]}",
//                                                 overflow: TextOverflow.ellipsis,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                       const Divider(height: 20),
//                                       Align(
//                                         alignment: Alignment.centerRight,
//                                         child: b["status"] == "pending"
//                                             ? ElevatedButton(
//                                                 onPressed: () => _cancelBooking(b),
//                                                 style: ElevatedButton.styleFrom(
//                                                   backgroundColor: Colors.red,
//                                                   foregroundColor: Colors.white,
//                                                   shape: RoundedRectangleBorder(
//                                                     borderRadius: BorderRadius.circular(8),
//                                                   ),
//                                                 ),
//                                                 child: const Text(
//                                                   "Cancel Booking",
//                                                   style: TextStyle(color: Colors.white),
//                                                 ),
//                                               )
//                                             : Container(
//                                                 padding: const EdgeInsets.symmetric(
//                                                     horizontal: 12, vertical: 6),
//                                                 decoration: BoxDecoration(
//                                                   color: b["status"] == "accepted"
//                                                       ? Colors.green
//                                                       : b["status"] == "declined"
//                                                           ? Colors.orange
//                                                           : b["status"] == "cancelled" || b["status"] == "cancel"
//                                                               ? Colors.red
//                                                               : Colors.grey,
//                                                   borderRadius: BorderRadius.circular(8),
//                                                 ),
//                                                 child: Text(
//                                                   b["status"].toString().toUpperCase(),
//                                                   style: const TextStyle(color: Colors.white),
//                                                 ),
//                                               ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../services/api_service.dart';

class Booking extends StatefulWidget {
  const Booking({super.key});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  String selectedFilter = "All";
  String searchQuery = "";
  DateTime? selectedDate;
  bool isLoading = true;
  String? userId;
  IO.Socket? socket;
  bool _isSocketConnected = false;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    // Clean up socket connection when widget is disposed
    socket?.off('bookingCreated');
    socket?.off('bookingUpdate');
    socket?.disconnect();
    socket?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadUserIdAndFetchBookings();
    _setupSocketListener();
  }

  // Load user ID first, then fetch bookings
  Future<void> _loadUserIdAndFetchBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');
      
      if (mounted) {
        setState(() {
          userId = storedUserId;
        });
      }
      
      print("📱 Loaded user ID for bookings: $userId");
      
      if (userId != null && userId!.isNotEmpty) {
        await _fetchBookings();
      } else {
        if (mounted) {
          setState(() => isLoading = false);
        }
        print("❌ No user ID found for bookings");
      }
    } catch (e) {
      print("❌ Error loading user ID: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _fetchBookings() async {
    if (userId == null || userId!.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await ApiService().getAllBookings(userId!);
      print("📋 Bookings API Response: ${response.data}");
      
      // Handle different response structures
      dynamic bookingsData;
      if (response.data is Map && response.data.containsKey('data')) {
        bookingsData = response.data['data'];
      } else if (response.data is List) {
        bookingsData = response.data;
      } else {
        bookingsData = [];
      }

      if (bookingsData is List) {
        bookings = List<Map<String, dynamic>>.from(bookingsData.map((b) {
          // Extract hospital data correctly
          final hospitalData = b["hospitalId"] is Map ? b["hospitalId"] : {};
          final hospitalName = hospitalData["name"] ?? "Unknown Hospital";
          final hospitalType = hospitalData["type"] ?? "General";
          final hospitalId = hospitalData["_id"] ?? b["hospitalId"] ?? "";

          return {
            "id": b["bookingId"] ?? b["_id"] ?? "",
            "hospital_id": hospitalId,
            "hospital": hospitalName,
            "type": hospitalType,
            "doctor": b["doctor_name"] ?? "Not specified",
            "specialty": b["specialty"] ?? "General",
            "date": _parseDate(b["booking_date"]),
            "status": (b["status"] ?? "pending").toString().toLowerCase(),
            "time": b["booking_time"] ?? "N/A",
            "patient_name": b["patient_name"] ?? "",
            "patient_phone": b["patient_phone"] ?? "",
            "patient_place": b["patient_place"] ?? "",
          };
        }));
      } else {
        bookings = [];
      }
      
      print("✅ Loaded ${bookings.length} bookings");
    } catch (e) {
      print("❌ Error fetching bookings: $e");
      bookings = [];
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _setupSocketListener() {
    try {
      // Replace with your backend URL
      const String serverUrl = 'https://www.zorrowtek.in';
      
      // Don't create socket if userId is null
      if (userId == null || userId!.isEmpty) {
        print("⚠️ Cannot setup socket: No user ID");
        return;
      }

      // Create socket options
      Map<String, dynamic> socketOptions = {
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'forceNew': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
      };

      // Create socket connection
      socket = IO.io(serverUrl, socketOptions);

      // Socket connection events
      socket!.on('connect', (_) {
        print("✅ Connected to server via Socket.IO");
        setState(() {
          _isSocketConnected = true;
        });
        
        // Join user-specific room after connection
        _joinUserRoom();
      });

      socket!.on('disconnect', (_) {
        print("🔌 Disconnected from server");
        setState(() {
          _isSocketConnected = false;
        });
      });

      socket!.on('reconnect', (_) {
        print("🔄 Reconnected to server");
        setState(() {
          _isSocketConnected = true;
        });
        // Rejoin user room after reconnection
        _joinUserRoom();
      });

      socket!.on('reconnect_attempt', (_) {
        print("🔄 Attempting to reconnect...");
      });

      socket!.on('reconnect_error', (error) {
        print('⚠️ Reconnection error: $error');
      });

      socket!.on('error', (error) {
        print('⚠️ Socket error: $error');
        setState(() {
          _isSocketConnected = false;
        });
      });

      // Listen for new booking notifications
      socket!.on('bookingCreated', (data) {
        print('📡 New booking notification received: $data');
        _handleSocketNotification(data, 'bookingCreated');
      });

      // Listen for booking update notifications
      socket!.on('bookingUpdate', (data) {
        print('📡 Booking update notification received: $data');
        _handleSocketNotification(data, 'bookingUpdate');
      });

      // Listen for booking status changes
      socket!.on('bookingStatusChanged', (data) {
        print('📡 Booking status change notification: $data');
        _handleSocketNotification(data, 'bookingStatusChanged');
      });

      socket!.connect();
      print('🔌 Socket.IO connection initiated for user: $userId');

    } catch (e) {
      print('❌ Error setting up socket: $e');
    }
  }

  void _joinUserRoom() {
    if (socket != null && socket!.connected && userId != null && userId!.isNotEmpty) {
      socket!.emit('joinUserRoom', {'userId': userId});
      
      // You can also request to join booking-specific rooms
      for (var booking in bookings) {
        if (booking['id'] != null && booking['id'].toString().isNotEmpty) {
          socket!.emit('joinBookingRoom', {'bookingId': booking['id']});
        }
      }
    }
  }

  void _handleSocketNotification(dynamic data, String eventType) {
    if (!mounted) return;
    
    try {
      // Extract user ID from notification data
      final notificationUserId = data['userId']?.toString();
      final bookingId = data['bookingId']?.toString();
      
      print('📱 Processing $eventType for user: $notificationUserId, booking: $bookingId');
      
      // Check if the notification is for this user
      if (notificationUserId == userId) {
        print('🔄 Refreshing bookings due to socket notification');
        
        // Show a snackbar to notify user
        if (eventType == 'bookingCreated') {
          showTopSnackBar(
            context, 
            "New booking created! Refreshing...",
            isError: false,
          );
        } else if (eventType == 'bookingUpdate' || eventType == 'bookingStatusChanged') {
          showTopSnackBar(
            context, 
            "Booking updated! Refreshing...",
            isError: false,
          );
        }
        
        // Refresh the bookings list
        _fetchBookings().then((_) {
          // Rejoin booking rooms after fetching new bookings
          if (_isSocketConnected) {
            _joinUserRoom();
          }
        });
      } else {
        print('🚫 This socket notification is for another user');
      }
    } catch (e) {
      print('❌ Error handling socket notification: $e');
    }
  }

  String _parseDate(dynamic date) {
    try {
      if (date == null) return "N/A";
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(date.toString()));
    } catch (e) {
      return "Invalid date";
    }
  }

  // Format time to ensure consistent display
  String _formatTime(dynamic time) {
    try {
      if (time == null || time == "N/A") return "N/A";
      
      String timeStr = time.toString().trim();
      
      // If time is already in a good format, return as is
      if (timeStr.contains(':') && timeStr.length <= 5) {
        return timeStr;
      }
      
      // Handle different time formats if needed
      if (timeStr.contains('T')) {
        // Handle ISO format
        DateTime dateTime = DateTime.parse(timeStr);
        return DateFormat('HH:mm').format(dateTime);
      }
      
      return timeStr;
    } catch (e) {
      return time?.toString() ?? "N/A";
    }
  }

  List<Map<String, dynamic>> get filteredBookings {
    return bookings.where((b) {
      final matchesFilter =
          selectedFilter == "All" || b["status"] == selectedFilter.toLowerCase();
      final matchesSearch = b["hospital"]
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          b["doctor"]
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
      final matchesDate = selectedDate == null ||
          b["date"] == DateFormat('yyyy-MM-dd').format(selectedDate!);
      return matchesFilter && matchesSearch && matchesDate;
    }).toList();
  }

  void _selectDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    final bookingId = booking["id"].toString();
    final hospitalId = booking["hospital_id"].toString();
    
    if (bookingId.isEmpty || hospitalId.isEmpty) {
      showTopSnackBar(context, "Invalid booking data", isError: true);
      return;
    }

    try {
      await ApiService().updateBooking(bookingId, hospitalId, {"status": "cancel"});
      if (mounted) {
        setState(() {
          booking["status"] = "cancel";
        });
      }
      showTopSnackBar(context, "Booking cancelled successfully");
      
      // Refresh bookings after cancellation
      await _fetchBookings();
    } catch (e) {
      print("❌ Error cancelling booking: $e");
      showTopSnackBar(context, "Failed to cancel booking", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show message if no user ID
    if (userId == null || userId!.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFECFDF5),
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text(
            "My Bookings",
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Please login to view your bookings",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bookingsToShow = filteredBookings;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "My Bookings",
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          // Socket connection indicator
          if (!_isSocketConnected)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.wifi_off, color: Colors.white, size: 20),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchBookings();
              if (!_isSocketConnected) {
                _setupSocketListener();
              }
            },
            tooltip: "Refresh bookings",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by hospital or doctor",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                  const SizedBox(height: 12),

                  // Date Filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate == null
                            ? "Filter by date"
                            : "Date: ${DateFormat('dd MMM yyyy').format(selectedDate!)}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text("Select Date"),
                      ),
                      if (selectedDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              selectedDate = null;
                            });
                          },
                        ),
                    ],
                  ),

                  // Status Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["All", "Pending", "Accepted", "Declined", "Cancelled"]
                          .map(
                            (f) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(f),
                                selected: selectedFilter == f,
                                onSelected: (_) {
                                  setState(() {
                                    selectedFilter = f;
                                    if (f == "All") {
                                      selectedDate = null;
                                      _searchController.clear();
                                      searchQuery = "";
                                    }
                                  });
                                },
                                selectedColor: Colors.green,
                                labelStyle: TextStyle(
                                  color: selectedFilter == f ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Booking List
                  Expanded(
                    child: bookingsToShow.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy, size: 60, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  "No bookings found",
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: bookingsToShow.length,
                            itemBuilder: (context, index) {
                              final b = bookingsToShow[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.local_hospital,
                                              color: Colors.green),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              b["hospital"],
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.person,
                                              color: Colors.blueAccent),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Doctor: ${b["doctor"]}",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.medical_services,
                                              color: Colors.orange),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Type: ${b["type"]}",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.health_and_safety,
                                              color: Colors.purple),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Specialty: ${b["specialty"]}",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              color: Colors.teal),
                                          const SizedBox(width: 8),
                                          Text("Date: ${b["date"]}"),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              color: Colors.redAccent),
                                          const SizedBox(width: 8),
                                          Text("Time: ${_formatTime(b["time"])}"),
                                        ],
                                      ),
                                      if (b["patient_name"]?.isNotEmpty == true) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline,
                                                color: Colors.brown),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Patient: ${b["patient_name"]}",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const Divider(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Status badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: b["status"] == "accepted"
                                                  ? Colors.green
                                                  : b["status"] == "declined"
                                                      ? Colors.orange
                                                      : b["status"] == "cancelled" || b["status"] == "cancel"
                                                          ? Colors.red
                                                          : b["status"] == "pending"
                                                              ? Colors.blue
                                                              : Colors.grey,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              b["status"].toString().toUpperCase(),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          // Cancel button only for pending bookings
                                          if (b["status"] == "pending")
                                            ElevatedButton(
                                              onPressed: () => _cancelBooking(b),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text("Cancel"),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
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
}