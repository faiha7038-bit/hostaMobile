import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/booking_provider.dart';
import 'package:intl/intl.dart';
import '../../../common/top_snackbar.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingStateProvider.notifier).initializeData();
    });
  }

  @override
  void dispose() {
    // Cleanup is handled by the provider
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(bookingStateProvider).selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      ref.read(bookingStateProvider.notifier).updateSelectedDate(picked);
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    try {
      await ref.read(bookingStateProvider.notifier).cancelBooking(booking);
      if (mounted) {
        showTopSnackBar(context, "Booking cancelled successfully");
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, "Failed to cancel booking", isError: true);
      }
    }
  }

  String _formatTime(dynamic time) {
    try {
      if (time == null || time == "N/A") return "N/A";

      String timeStr = time.toString().trim();

      if (timeStr.contains(':') && timeStr.length <= 5) {
        return timeStr;
      }

      if (timeStr.contains('T')) {
        DateTime dateTime = DateTime.parse(timeStr);
        return DateFormat('HH:mm').format(dateTime);
      }

      return timeStr;
    } catch (e) {
      return time?.toString() ?? "N/A";
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingStateProvider);
    final filteredBookings = ref.watch(filteredBookingsProvider);
    final userId = bookingState.userId;
    final isLoading = bookingState.isLoading;
    final isSocketConnected = bookingState.isSocketConnected;
    final selectedFilter = bookingState.selectedFilter;
    final selectedDate = bookingState.selectedDate;
    final searchController = bookingState.searchController;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

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
         if (!isSocketConnected)
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
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search by hospital or doctor",
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
                    onChanged: (value) {
                      ref.read(bookingStateProvider.notifier).updateSearchQuery(value);
                    },
                  ),
                  SizedBox(height: screenHeight * 0.015),

                  // Date Filter
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
                      if (selectedDate != null)
                        IconButton(
                          icon: Icon(Icons.clear, size: screenWidth * 0.045),
                          onPressed: () {
                            ref.read(bookingStateProvider.notifier).clearSelectedDate();
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
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                              child: ChoiceChip(
                                label: Text(
                                  f,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                                selected: selectedFilter == f,
                                onSelected: (_) {
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
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredBookings.length,
                            itemBuilder: (context, index) {
                              final b = filteredBookings[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                                margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                                elevation: isSmallScreen ? 2 : 3,
                                child: Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.03),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.local_hospital,
                                              color: Colors.green, size: screenWidth * 0.06),
                                          SizedBox(width: screenWidth * 0.02),
                                          Expanded(
                                            child: Text(
                                              b["hospital"],
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: screenWidth * 0.04),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.0075),
                                      Row(
                                        children: [
                                          Icon(Icons.person,
                                              color: Colors.blueAccent, size: screenWidth * 0.05),
                                          SizedBox(width: screenWidth * 0.02),
                                          Expanded(
                                            child: Text(
                                              "Doctor: ${b["doctor"]}",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: screenWidth * 0.035),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      Row(
                                        children: [
                                          Icon(Icons.medical_services,
                                              color: Colors.orange, size: screenWidth * 0.05),
                                          SizedBox(width: screenWidth * 0.02),
                                          Expanded(
                                            child: Text(
                                              "Type: ${b["type"]}",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: screenWidth * 0.035),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      Row(
                                        children: [
                                          Icon(Icons.health_and_safety,
                                              color: Colors.purple, size: screenWidth * 0.05),
                                          SizedBox(width: screenWidth * 0.02),
                                          Expanded(
                                            child: Text(
                                              "Specialty: ${b["specialty"]}",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: screenWidth * 0.035),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, color: Colors.green, size: screenWidth * 0.05),
                                          SizedBox(width: screenWidth * 0.02),
                                          Text(
                                            "Date: ${b["date"]}",
                                            style: TextStyle(fontSize: screenWidth * 0.035),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, color: Colors.green, size: screenWidth * 0.05),
                                          SizedBox(width: screenWidth * 0.02),
                                          Text(
                                            "Time: ${_formatTime(b["time"])}",
                                            style: TextStyle(fontSize: screenWidth * 0.035),
                                          ),
                                        ],
                                      ),
                                      if (b["patient_name"]?.isNotEmpty == true) ...[
                                        SizedBox(height: screenHeight * 0.005),
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline, color: Colors.green, size: screenWidth * 0.05),
                                            SizedBox(width: screenWidth * 0.02),
                                            Expanded(
                                              child: Text(
                                                "Patient: ${b["patient_name"]}",
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: screenWidth * 0.035),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      Divider(height: screenHeight * 0.025),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Status badge
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: screenWidth * 0.03, 
                                               
                                              vertical: screenHeight * 0.005,
                                            ),
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
                                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                            ),
                                            child: Text(
                                              b["status"].toString().toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: screenWidth * 0.03,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Cancel button only for pending bookings
                                          if (b["status"] == "pending")
                                            ElevatedButton(
                                              onPressed: () => _cancelBooking(b),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: screenWidth * 0.04,
                                                  vertical: screenHeight * 0.01,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                                ),
                                              ),
                                              child: Text(
                                                "Cancel",
                                                style: TextStyle(fontSize: screenWidth * 0.035),
                                              ),
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