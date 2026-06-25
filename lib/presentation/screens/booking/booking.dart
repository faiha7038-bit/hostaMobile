import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/booking_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/top_snackbar.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;
  @override
  void initState() {
    super.initState();
      _checkToken();
      
    print("📌 BookingScreen initState called");
    // Initialize data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingStateProvider.notifier).initializeData();
    });
_scrollController.addListener(() {
  if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent - 200) {

    if (_isFetchingMore) return;

    _isFetchingMore = true;

    ref.read(bookingStateProvider.notifier).loadMore()
      .then((_) => _isFetchingMore = false);
  }
});
  }
  String formatBookingDate(String? date) {
  if (date == null || date.isEmpty) return "N/A";

  try {
    final parsedDate = DateTime.parse(date);
    return DateFormat('dd/MM/yyyy').format(parsedDate);
  } catch (e) {
    return date;
  }
}
 Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final userId = prefs.getString('userId');
    
    print('🔐 Token exists: ${token != null}');
    print('👤 User ID: $userId');
    print('🔐 Token value: ${token != null ? token!.substring(0, 20) + "..." : "NULL"}');
    
    if (token == null) {
      print('❌ TOKEN MISSING - Please login again');
      // Optional: Show dialog to login
      // _showLoginDialog();
    } else {
       print('✅ Token found - Booking will work');
    }
  }
  

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selectedDate = ref.read(bookingStateProvider).selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
      log("PICKED DATE => $picked");
    if (picked != null && mounted) {
      ref.read(bookingStateProvider.notifier).updateSelectedDate(picked);
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
     showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
    
  );
    try {
      await ref.read(bookingStateProvider.notifier).cancelBooking(booking);
      if (mounted && Navigator.canPop(context)) {
         Navigator.pop(context);
        showTopSnackBar(context, "Booking cancelled successfully");
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
         Navigator.pop(context);
        showTopSnackBar(context, "Failed to cancel booking", isError: true);
      }
    }
  }
  String _formatTime(dynamic time) {
  try {
    if (time == null || time.toString().isEmpty) {
      return "Waiting for hospital confirmation";
    }

    final timeStr = time.toString();

    // If ISO datetime
    if (timeStr.contains('T')) {
      final dateTime = DateTime.parse(timeStr);
      return DateFormat('hh:mm a').format(dateTime);
    }

    // HH:mm format
    if (timeStr.contains(':')) {
      final parts = timeStr.split(':');

      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final now = DateTime.now();

        final parsedTime = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        return DateFormat('hh:mm a').format(parsedTime);
      }
    }

    return timeStr;
  } catch (e) {
    return time.toString();
  }
}



  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingStateProvider);
    final filteredBookings = ref.watch(filteredBookingsProvider);
    
    final userId = bookingState.userId;
    final isLoading = bookingState.isLoading;
    //final isSocketConnected = bookingState.isSocketConnected;
    final selectedFilter = bookingState.selectedFilter;
    final selectedDate = bookingState.selectedDate;
    final searchController = bookingState.searchController;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
   // final isSmallScreen = screenWidth < 600;

    // Show message if no user ID
    if (userId == null || userId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFECFDF5),
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: Text(
            "My Bookings",
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: Colors.white,
              fontSize: screenWidth * 0.05,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: screenWidth * 0.15, color: Colors.grey),
              SizedBox(height: screenHeight * 0.02),
              Text(
                "Please login to view your bookings",
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
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "My Bookings",
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
        actions: [
          // Socket connection indicator
         // if (!isSocketConnected)
            Padding(
              padding: EdgeInsets.only(right: screenWidth * 0.02),
              child: Icon(Icons.wifi_off, color: Colors.white, size: screenWidth * 0.05),
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white, size: screenWidth * 0.06),
            onPressed: () {
              ref.read(bookingStateProvider.notifier).refreshBookings();
            },
            tooltip: "Refresh bookings",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search bookings",
                      prefixIcon: Icon(Icons.search, size: screenWidth * 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.015,
                      ),
                    ),
                    onChanged: (value)  {
                      ref.read(bookingStateProvider.notifier).updateSearchQuery(value);
                     log("hhhhhh");
                    },
                  ),
                  SizedBox(height: screenHeight * 0.015),

                  // Date Filter Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate == null
                            ? "Filter by date"
                            : "Date: ${DateFormat('dd MMM yyyy').format(selectedDate!)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _selectDate,
                        icon: Icon(Icons.calendar_today, size: screenWidth * 0.045),
                        label: Text(
                          "Select Date",
                          style: TextStyle(fontSize: screenWidth * 0.035),
                        ),
                      ),
                     if (ref.watch(bookingStateProvider).selectedDate != null)
                        IconButton(
                          icon: Icon(Icons.clear, size: screenWidth * 0.045),
                          onPressed: () {
                            ref.read(bookingStateProvider.notifier).clearSelectedDate();
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),

                  // Status Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["All", "Pending", "Accepted", "Declined", "Cancelled","Completed"]
                          .map(
                            (f) => Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                              child: ChoiceChip(
                                label: Text(
                                  f,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                                selected: selectedFilter == f,
                                onSelected: (_)async {
                                ref.read(bookingStateProvider.notifier).updateSelectedFilter(f);
                                },
                                selectedColor: Colors.green,
                                labelStyle: TextStyle(
                                  color: selectedFilter == f ? Colors.white : Colors.black,
                                  fontSize: screenWidth * 0.035,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Booking List
                  Expanded(
                    child: filteredBookings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy, size: screenWidth * 0.12, color: Colors.grey),
                                SizedBox(height: screenHeight * 0.02),
                                Text(
                                  "No bookings found",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                // Text(
                                //   "Try changing your filters",
                                //   style: TextStyle(
                                //     fontSize: screenWidth * 0.035,
                                //     color: Colors.grey[400],
                                //   ),
                                // ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                        itemCount: filteredBookings.length + (bookingState.hasNextPage ? 1 : 0),
itemBuilder: (context, index) {
  if (index < filteredBookings.length) {
    final b = filteredBookings[index];
    return _buildBookingCard(b, screenWidth, screenHeight);
  } else {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
},
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, double screenWidth, double screenHeight) {
    final status = booking["status"].toString().toLowerCase();
    
    Color getStatusColor() {
      switch (status) {
        case "accepted": return Colors.green;
        case "declined": return Colors.orange;
        case "cancelled": 
        case "cancel": return Colors.red;
        case "pending": return Colors.blue;
        default: return Colors.grey;
      }
    }

    String getStatusText() {
      switch (status) {
        case "accepted": return "ACCEPTED";
        case "declined": return "DECLINED";
        case "cancelled": 
        case "cancel": return "CANCELLED";
        case "pending": return "PENDING";
        default: return status.toUpperCase();
      }
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03)
      ),
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hospital Name
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Icon(Icons.local_hospital, color: Colors.green, size: screenWidth * 0.06),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking["hospital"] ?? "Unknown Hospital",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.04,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (booking["type"] != null && booking["type"] != "General")
                        Text(
                          booking["type"],
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: Text(
                    getStatusText(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: screenHeight * 0.015),
            
            // Doctor Name
            _buildInfoRow(
              Icons.person,
              "Doctor",
              booking["doctor"] ?? "Not specified",
              screenWidth,
            ),
            
            SizedBox(height: screenHeight * 0.008),
            
            // Specialty
            _buildInfoRow(
              Icons.medical_services,
              "Specialty",
              booking["specialty"] ?? "General",
              screenWidth,
            ),
            
            SizedBox(height: screenHeight * 0.008),
            
            // Date
          _buildInfoRow(
  Icons.calendar_today,
  "Date",
  formatBookingDate(booking["date"]),
  screenWidth,
),
            SizedBox(height: screenHeight * 0.008),

// TOKEN NUMBER
_buildInfoRow(
  Icons.confirmation_number,
  "Token",
  booking["token"] ?? "Not Assigned",
  screenWidth,
),
            
            SizedBox(height: screenHeight * 0.008),
            
            // Time
            // _buildInfoRow(
            //   Icons.access_time,
            //   "Time",
            //   _formatTime(booking["time"]),
            //   screenWidth,
            // ),
            // Consulting Time from backend
//if (booking["consulting_time"] != null)
_buildInfoRow(
  Icons.access_time,
  "Consulting Time",
  _formatTime(booking["time"]),
  screenWidth,
),
            
            // Patient Name (if available)
            if (booking["patient_name"] != null && booking["patient_name"].toString().isNotEmpty) ...[
              SizedBox(height: screenHeight * 0.008),
              _buildInfoRow(
                Icons.person_outline,
                "Patient",
                booking["patient_name"],
                screenWidth,
              ),
            ],
            
            SizedBox(height: screenHeight * 0.015),
            
            const Divider(),
            
            SizedBox(height: screenHeight * 0.01),
            
            // Cancel Button (only for pending bookings)
            if (status == "pending")
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
              ElevatedButton.icon(
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Booking"),
        content: const Text(
          "Are you sure you want to cancel this booking?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No",style: TextStyle(color: Colors.grey),),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _cancelBooking(booking);
    }
  },
  icon: Icon(Icons.cancel, size: screenWidth * 0.045),
  label: Text(
    "Cancel Booking",
    style: TextStyle(fontSize: screenWidth * 0.035),
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
  ),
),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, double screenWidth) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: screenWidth * 0.045),
        SizedBox(width: screenWidth * 0.03),
        SizedBox(
          width: screenWidth * 0.2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: screenWidth * 0.035,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}