import 'dart:async';
import 'dart:core';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../services/api_service.dart';

// ─────────────────────────────────────────────
//  STATE CLASSES
// ─────────────────────────────────────────────

class BookingState {
  final String selectedFilter;
  final String searchQuery;
  final DateTime? selectedDate;
  final bool isLoading;
  final String? userId;
  final bool isSocketConnected;
  final List<Map<String, dynamic>> bookings;
  final TextEditingController searchController;
  final int currentPage;
  final bool hasNextPage;
  final bool isLoadingMore;

  BookingState({
    this.selectedFilter = "All",
    this.searchQuery = "",
    this.selectedDate,
    this.isLoading = true,
    this.userId,
    this.isSocketConnected = false,
    this.bookings = const [],

    required this.searchController,
      this.currentPage = 1,
    this.hasNextPage = true,
    this.isLoadingMore = false,
    
  });

  BookingState copyWith({
    String? selectedFilter,
    String? searchQuery,
    DateTime? selectedDate,
    bool? isLoading,
    String? userId,
    bool? isSocketConnected,
    List<Map<String, dynamic>>? bookings,
    TextEditingController? searchController,
    int? currentPage,
  bool? hasNextPage,
  bool? isLoadingMore,
  bool clearDate = false, 
  }) {
    return BookingState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
  selectedDate: clearDate
        ? null
        : (selectedDate ?? this.selectedDate),
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      bookings: bookings ?? this.bookings,
      searchController: searchController ?? this.searchController,
       currentPage: currentPage ?? this.currentPage,
    hasNextPage: hasNextPage ?? this.hasNextPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ─────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────

final bookingStateProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier();
});

class BookingNotifier extends StateNotifier<BookingState> {
  Timer? _debounce;
  IO.Socket? _socket;
  final ApiService _apiService = ApiService();

  BookingNotifier() : super(
    BookingState(
      searchController: TextEditingController(),
    ),
  );
Future<void> loadMore() async {
  if (state.isLoadingMore || !state.hasNextPage) return;

  state = state.copyWith(isLoadingMore: true);

  final nextPage = state.currentPage + 1;

  await fetchBookings(
    reset: false,
    page: nextPage,
  );

log("OLD BOOKINGS = ${state.bookings.length}");

  state = state.copyWith(isLoadingMore: false);
}

  Future<void> updateSelectedFilter(String filter)async {
    state = state.copyWith(
      selectedFilter: filter,
      selectedDate: filter == "All" ? null : state.selectedDate,
      searchQuery: filter == "All" ? "" : state.searchQuery,
    );
    if (filter == "All") {
      state.searchController.clear();
    }
     await fetchBookings();
  }

  Future<void> updateSearchQuery(String query) async {
  state = state.copyWith(searchQuery: query);

  _debounce?.cancel();

  _debounce = Timer(
    const Duration(milliseconds: 500),
    ()  {
       fetchBookings();
    },
  );
}

Future<void> updateSelectedDate(DateTime? date) async {
  print("STATE DATE => $date");

  state = state.copyWith(selectedDate: date);

  print("AFTER UPDATE => ${state.selectedDate}");

  await fetchBookings();
}
Future<void> clearSelectedDate() async {
  state = state.copyWith(clearDate: true);

  log("DATE AFTER CLEAR = ${state.selectedDate}");

  await fetchBookings();
}

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setUserId(String? userId) {
    state = state.copyWith(userId: userId);
  }

  void setSocketConnected(bool connected) {
    state = state.copyWith(isSocketConnected: connected);
  }

  void setBookings(List<Map<String, dynamic>> bookings) {
    state = state.copyWith(bookings: bookings);
  }

  // void updateBookingStatus(String bookingId, String newStatus) {
  //   final updatedBookings = state.bookings.map((booking) {
  //     if (booking["id"] == bookingId) {
  //       return {...booking, "status": newStatus};
  //     }
  //     return booking;
  //   }).toList();
  //   state = state.copyWith(bookings: updatedBookings);
  // }
void updateBookingStatus(String bookingId, String newStatus) {
  final updatedBookings = state.bookings.map((booking) {
    if (booking["id"].toString() == bookingId.toString()) {
      return {
        ...booking,
        "status": newStatus,
      };
    }
    return booking;
  }).toList();

  state = state.copyWith(bookings: updatedBookings);
}
  Future<void> initializeData() async {
    await loadUserIdAndFetchBookings();
    setupSocketListener();
  }



Future<void> loadUserIdAndFetchBookings() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    String? storedUserId =
        prefs.getString('userId') ??
        prefs.getInt('userId')?.toString();

    print("USER ID FOUND = $storedUserId");

    setUserId(storedUserId);

    if (storedUserId != null && storedUserId.isNotEmpty) {
      await fetchBookings();
    } else {
      setLoading(false);
    }
  } catch (e) {
    print(e);
    setLoading(false);
  }
}
Future<void> fetchBookings({
  
  bool reset = true,
  int? page,
}) async {
  final userId = state.userId;
log("RESET = $reset");
  if (userId == null || userId.isEmpty) {
    setLoading(false);
    return;
  }
log("SELECTED DATE FROM STATE => ${state.selectedDate}");
log("SELECTED DATE => ${state.selectedDate}");
log("DATE SENT TO API => ${state.selectedDate == null ? null : DateFormat('yyyy-MM-dd').format(state.selectedDate!)}");
log("DATE BEFORE RESET => ${state.selectedDate}");
  if (reset) {
    state = state.copyWith(
      currentPage: 1,
      bookings: [],
      hasNextPage: true,
       isLoading: state.bookings.isEmpty,
    );
  }

  try {
    final formattedDate = state.selectedDate == null
    ? null
    : DateFormat('yyyy-MM-dd').format(state.selectedDate!);

log("FORMATTED DATE BEFORE API = $formattedDate");
   final response = await _apiService.getAllBookings(
    
  userId: userId,
  status: state.selectedFilter == "All"
      ? null
      : state.selectedFilter.toLowerCase() == "cancelled"
          ? "cancel"
          : state.selectedFilter.toLowerCase(),
  searchQuery: state.searchQuery.isEmpty
      ? null
      : state.searchQuery,
  date: formattedDate,
  page: page ?? state.currentPage,
  limit: 10,
);
log("responseof=booking${response.data}");
    final data = response.data;

    List<Map<String, dynamic>> parsedBookings = [];

    if (data is Map && data['data'] is List) {
      parsedBookings = _parseBookings(data['data']);
    }

    final pagination = data['pagination'];

    state = state.copyWith(
      bookings: reset
          ? parsedBookings
          : [...state.bookings, ...parsedBookings],
      hasNextPage: pagination['hasNextPage'],
    currentPage: (page ?? state.currentPage),
    );
log("API COUNT = ${parsedBookings.length}");
  } catch (e) {
    setBookings([]);
  } finally {
    setLoading(false);
  }
}

List<Map<String, dynamic>> _parseBookings(List<dynamic> bookingsData) {
  return bookingsData.map<Map<String, dynamic>>((b) {
    log("BOOKING RAW = $b");
log("CONSULTING TIME = ${b["consulting_time"]}");
    return {
      "id": b["id"]?.toString() ?? "",

      "hospital_id": b["hospitalId"]?.toString() ?? "",

      "hospital": b["hospitalName"]?.toString() ??
          b["hospital_name"]?.toString() ??
          "Hospital",

      "doctor": b["doctor_name"]?.toString() ??
          b["doctorName"]?.toString() ??
          "Not specified",

      "specialty": b["doctor_department"]?.toString() ??
          b["doctorSpecialty"]?.toString() ??
          b["specialty"]?.toString() ??
          "General",

      "date": _parseDate(
        b["booking_date"] ??
        b["bookingDate"] ??
        b["date"],
      ),

      "status": (b["status"] ?? "pending").toString().toLowerCase(),
      // "time": b["consultingTime"]?.toString() ?? 
      //         b["time"]?.toString() ?? 
      //         b["booking_time"]?.toString() ?? 
      //         "N/A",
      
   

      // TOKEN
      "token": b["token"]?.toString() ?? "Not Assigned",
      "time": b["consulting_time"]?.toString() ?? 
        b["consultingTime"]?.toString() ?? 
        b["time"]?.toString() ?? 
        b["booking_time"]?.toString() ?? 
        "",
        
      "patient_name": b["patientName"]?.toString() ?? 
                      b["patient_name"]?.toString() ?? 
                      "",
      "patient_phone": b["patientPhone"]?.toString() ?? 
                       b["patient_phone"]?.toString() ?? 
                       "",
      "patient_place": b["patientPlace"]?.toString() ?? 
                       b["patient_place"]?.toString() ?? 
                       "",
                       
    };
    
  }).toList();
  
}

  String _parseDate(dynamic date) {
    try {
      if (date == null) return "N/A";
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(date.toString()));
    } catch (e) {
      return "Invalid date";
    }
  }

  void setupSocketListener() {
    try {
      const String serverUrl = 'https://www.zorrowtek.in';
      final userId = state.userId;

      if (userId == null || userId.isEmpty) {
        print("⚠️ Cannot setup socket: No user ID");
        return;
      }

      // Clean up existing socket
      _disposeSocket();

      Map<String, dynamic> socketOptions = {
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'forceNew': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
      };

      _socket = IO.io(serverUrl, socketOptions);

      _socket!.on('connect', (_) {
        print("✅ Connected to server via Socket.IO");
        setSocketConnected(true);
        _joinUserRoom();
      });

      _socket!.on('disconnect', (_) {
        print("🔌 Disconnected from server");
        setSocketConnected(false);
      });

      _socket!.on('reconnect', (_) {
        print("🔄 Reconnected to server");
        setSocketConnected(true);
        _joinUserRoom();
      });

      _socket!.on('reconnect_attempt', (_) {
        print("🔄 Attempting to reconnect...");
      });

      _socket!.on('reconnect_error', (error) {
        print('⚠️ Reconnection error: $error');
      });

      _socket!.on('error', (error) {
        print('⚠️ Socket error: $error');
        setSocketConnected(false);
      });

      _socket!.on('bookingCreated', (data) {
        print('📡 New booking notification received: $data');
        _handleSocketNotification(data, 'bookingCreated');
      });

      _socket!.on('bookingUpdate', (data) {
        print('📡 Booking update notification received: $data');
        _handleSocketNotification(data, 'bookingUpdate');
      });

      _socket!.on('bookingStatusChanged', (data) {
        print('📡 Booking status change notification: $data');
        _handleSocketNotification(data, 'bookingStatusChanged');
      });

      _socket!.connect();
      print('🔌 Socket.IO connection initiated for user: $userId');
    } catch (e) {
      print('❌ Error setting up socket: $e');
    }
  }

  void _joinUserRoom() {
    final userId = state.userId;
    if (_socket != null && _socket!.connected && userId != null && userId.isNotEmpty) {
      _socket!.emit('joinUserRoom', {'userId': userId});

      for (var booking in state.bookings) {
        if (booking['id'] != null && booking['id'].toString().isNotEmpty) {
          _socket!.emit('joinBookingRoom', {'bookingId': booking['id']});
        }
      }
    }
  }

  void _handleSocketNotification(dynamic data, String eventType) {
    try {
      final notificationUserId = data['userId']?.toString();
      final userId = state.userId;

      print('📱 Processing $eventType for user: $notificationUserId');

      if (notificationUserId == userId) {
        print('🔄 Refreshing bookings due to socket notification');
        fetchBookings().then((_) {
          if (_socket != null && _socket!.connected) {
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

 Future<void> cancelBooking(Map<String, dynamic> booking) async {
  final bookingId = booking["id"].toString();
  final hospitalId = booking["hospital_id"].toString();

  if (bookingId.isEmpty || hospitalId.isEmpty) {
    throw Exception("Invalid booking data");
  }

  try {
await _apiService.updateBooking(
  bookingId,
  {"status": "cancel"},
);

    updateBookingStatus(
      bookingId,
      "cancel",
    );

    await fetchBookings();

  } catch (e) {
    print("❌ Error cancelling booking: $e");
    rethrow;
  }
}

  void refreshBookings() {
    fetchBookings();
    if (!state.isSocketConnected) {
      setupSocketListener();
    }
  }

  void _disposeSocket() {
    _socket?.off('bookingCreated');
    _socket?.off('bookingUpdate');
    _socket?.off('bookingStatusChanged');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  @override
  void dispose() {
    _disposeSocket();
    state.searchController.dispose();
    super.dispose();
  }
}

final filteredBookingsProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(bookingStateProvider).bookings;
});
