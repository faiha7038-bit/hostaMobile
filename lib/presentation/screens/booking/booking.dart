import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/booking_provider.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/top_snackbar.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;
  bool _listenerAdded = false;
  late Function(dynamic) _onBookingEvent;

  @override
  void initState() {
    super.initState();
    _checkToken();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingStateProvider.notifier).initializeData();
    });
    _setupSocketListener();
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
    // (code as original)
  }

  void _setupSocketListener() {
    if (_listenerAdded) return;
    _listenerAdded = true;
    final notifier = ref.read(bookingStateProvider.notifier);
    _onBookingEvent = (data) async {
      notifier.setLoading(true);
      await notifier.fetchBookings(reset: true);
    };
    SocketService().addListener(
      [
        'BOOKING_REGISTERED',
        'BOOKING_UPDATED',
        'BOOKING_CANCELLED',
        'BOOKING_ACCEPTED',
        'BOOKING_COMPLETED',
      ],
      _onBookingEvent,
    );
  }

  @override
  void dispose() {
    SocketService().removeListener("BOOKING_REGISTERED", _onBookingEvent);
    SocketService().removeListener("BOOKING_UPDATED", _onBookingEvent);
    SocketService().removeListener("BOOKING_CANCELLED", _onBookingEvent);
    SocketService().removeListener("BOOKING_ACCEPTED", _onBookingEvent);
    SocketService().removeListener("BOOKING_COMPLETED", _onBookingEvent);
    _scrollController.dispose();
    super.dispose();
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
      if (timeStr.contains('T')) {
        final dateTime = DateTime.parse(timeStr);
        return DateFormat('hh:mm a').format(dateTime);
      }
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final now = DateTime.now();
          final parsedTime = DateTime(
            now.year, now.month, now.day, hour, minute,
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
    final selectedFilter = bookingState.selectedFilter;
    final selectedDate = bookingState.selectedDate;
    final searchController = bookingState.searchController;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive clamped values
    final double appBarTitleSize = _clamp(screenWidth * 0.05, 16, 24);
    final double pagePadding = _clamp(screenWidth * 0.04, 12, 24);
    final double searchRadius = _clamp(screenWidth * 0.03, 8, 16);
    final double searchIconSize = _clamp(screenWidth * 0.06, 20, 32);
    final double searchContentPadH = _clamp(screenWidth * 0.04, 12, 24);
    final double searchContentPadV = _clamp(screenHeight * 0.015, 8, 16);
    final double spacingSmall = _clamp(screenHeight * 0.015, 8, 16);
    final double spacingMedium = _clamp(screenHeight * 0.02, 12, 24);
    final double filterChipFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double chipHorizontalPadding = _clamp(screenWidth * 0.01, 4, 12);
    final double emptyIconSize = _clamp(screenWidth * 0.12, 48, 80);
    final double emptyTextSize = _clamp(screenWidth * 0.04, 14, 22);
    final double buttonFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double calendarIconSize = _clamp(screenWidth * 0.045, 16, 24);
    final double clearIconSize = _clamp(screenWidth * 0.045, 16, 24);
    final double iconSizeLarge = _clamp(screenWidth * 0.15, 60, 100);
    final double cardRadius = _clamp(screenWidth * 0.03, 8, 16);
    final double cardMarginVertical = _clamp(screenHeight * 0.01, 6, 16);
    final double cardPadding = _clamp(screenWidth * 0.04, 12, 24);
    final double hospitalIconSize = _clamp(screenWidth * 0.06, 24, 40);
    final double infoIconSize = _clamp(screenWidth * 0.045, 16, 24);
    final double labelWidth = _clamp(screenWidth * 0.2, 60, 120);
    final double infoTextSize = _clamp(screenWidth * 0.035, 12, 18);
    final double statusBadgeFontSize = _clamp(screenWidth * 0.03, 10, 16);
    final double statusBadgeHorizPad = _clamp(screenWidth * 0.03, 8, 16);
    final double statusBadgeVertPad = _clamp(screenHeight * 0.005, 4, 10);
    final double buttonIconSize = _clamp(screenWidth * 0.045, 16, 24);

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
              fontSize: appBarTitleSize,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: emptyIconSize, color: Colors.grey),
              SizedBox(height: spacingMedium),
              Text(
                "Please login to view your bookings",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: emptyTextSize,
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
            fontSize: appBarTitleSize,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.green,
                strokeWidth: _clamp(screenWidth * 0.008, 2, 6),
              ),
            )
          : Padding(
              padding: EdgeInsets.all(pagePadding),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search bookings",
                      prefixIcon: Icon(Icons.search, size: searchIconSize),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(searchRadius),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: searchContentPadH,
                        vertical: searchContentPadV,
                      ),
                    ),
                    onChanged: (value) {
                      ref.read(bookingStateProvider.notifier).updateSearchQuery(value);
                    },
                  ),
                  SizedBox(height: spacingSmall),

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
                          fontSize: infoTextSize,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _selectDate,
                        icon: Icon(Icons.calendar_today, size: calendarIconSize),
                        label: Text(
                          "Select Date",
                          style: TextStyle(fontSize: infoTextSize),
                        ),
                      ),
                      if (ref.watch(bookingStateProvider).selectedDate != null)
                        IconButton(
                          icon: Icon(Icons.clear, size: clearIconSize),
                          onPressed: () {
                            ref.read(bookingStateProvider.notifier).clearSelectedDate();
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: spacingSmall),

                  // Status Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["All", "Pending", "Accepted", "Declined", "Cancelled", "Completed"]
                          .map(
                            (f) => Padding(
                              padding: EdgeInsets.symmetric(horizontal: chipHorizontalPadding),
                              child: ChoiceChip(
                                label: Text(
                                  f,
                                  style: TextStyle(
                                    fontSize: filterChipFontSize,
                                  ),
                                ),
                                selected: selectedFilter == f,
                                onSelected: (_) async {
                                  ref.read(bookingStateProvider.notifier).updateSelectedFilter(f);
                                },
                                selectedColor: Colors.green,
                                labelStyle: TextStyle(
                                  color: selectedFilter == f ? Colors.white : Colors.black,
                                  fontSize: filterChipFontSize,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  SizedBox(height: spacingSmall),

                  // Booking List
                  Expanded(
                    child: filteredBookings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy, size: emptyIconSize, color: Colors.grey),
                                SizedBox(height: spacingSmall),
                                Text(
                                  "No bookings found",
                                  style: TextStyle(
                                    fontSize: emptyTextSize,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: spacingSmall),
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
                                return Padding(
                                  padding: EdgeInsets.all(pagePadding),
                                  child: const Center(child: CircularProgressIndicator()),
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

    // Responsive clamped values for card
    final double cardRadius = _clamp(screenWidth * 0.03, 8, 16);
    final double cardMarginVertical = _clamp(screenHeight * 0.01, 6, 16);
    final double cardPadding = _clamp(screenWidth * 0.04, 12, 24);
    final double hospitalIconSize = _clamp(screenWidth * 0.06, 24, 40);
    final double titleFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double subtitleFontSize = _clamp(screenWidth * 0.03, 10, 16);
    final double statusBadgeFontSize = _clamp(screenWidth * 0.03, 10, 16);
    final double statusBadgeHorizPad = _clamp(screenWidth * 0.03, 8, 16);
    final double statusBadgeVertPad = _clamp(screenHeight * 0.005, 4, 10);
    final double infoIconSize = _clamp(screenWidth * 0.045, 16, 24);
    final double labelWidth = _clamp(screenWidth * 0.2, 60, 120);
    final double infoTextSize = _clamp(screenWidth * 0.035, 12, 18);
    final double buttonIconSize = _clamp(screenWidth * 0.045, 16, 24);
    final double buttonFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double spacingSmall = _clamp(screenHeight * 0.008, 6, 12);
    final double spacingMedium = _clamp(screenHeight * 0.015, 8, 16);
    final double spacingLarge = _clamp(screenHeight * 0.02, 12, 24);

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
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      margin: EdgeInsets.symmetric(vertical: cardMarginVertical),
      elevation: _clamp(screenWidth * 0.0075, 2, 6),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hospital Name
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(cardPadding * 0.5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(cardPadding * 0.5),
                  ),
                  child: Icon(Icons.local_hospital, color: Colors.green, size: hospitalIconSize),
                ),
                SizedBox(width: cardPadding * 0.75),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking["hospital"] ?? "Unknown Hospital",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (booking["type"] != null && booking["type"] != "General")
                        Text(
                          booking["type"],
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: statusBadgeHorizPad,
                    vertical: statusBadgeVertPad,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(),
                    borderRadius: BorderRadius.circular(statusBadgeHorizPad),
                  ),
                  child: Text(
                    getStatusText(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: statusBadgeFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: spacingSmall),

            // Doctor Name
            _buildInfoRow(
              Icons.person,
              "Doctor",
              booking["doctor"] ?? "Not specified",
              infoIconSize,
              labelWidth,
              infoTextSize,
            ),

            SizedBox(height: spacingSmall),

            // Specialty
            _buildInfoRow(
              Icons.medical_services,
              "Specialty",
              booking["specialty"] ?? "General",
              infoIconSize,
              labelWidth,
              infoTextSize,
            ),

            SizedBox(height: spacingSmall),

            // Date
            _buildInfoRow(
              Icons.calendar_today,
              "Date",
              formatBookingDate(booking["date"]),
              infoIconSize,
              labelWidth,
              infoTextSize,
            ),
            SizedBox(height: spacingSmall),

            // Token Number
            _buildInfoRow(
              Icons.confirmation_number,
              "Token",
              booking["token"] ?? "Not Assigned",
              infoIconSize,
              labelWidth,
              infoTextSize,
            ),

            SizedBox(height: spacingSmall),

            // Consulting Time
            _buildInfoRow(
              Icons.access_time,
              "Consulting Time",
              _formatTime(booking["time"]),
              infoIconSize,
              labelWidth,
              infoTextSize,
            ),

            // Patient Name (if available)
            if (booking["patient_name"] != null && booking["patient_name"].toString().isNotEmpty) ...[
              SizedBox(height: spacingSmall),
              _buildInfoRow(
                Icons.person_outline,
                "Patient",
                booking["patient_name"],
                infoIconSize,
                labelWidth,
                infoTextSize,
              ),
            ],

            SizedBox(height: spacingMedium),

            const Divider(),

            SizedBox(height: spacingSmall),

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
                          title: Text(
                            "Cancel Booking",
                            style: TextStyle(
                              fontSize: _clamp(screenWidth * 0.05, 18, 28),
                            ),
                          ),
                          content: Text(
                            "Are you sure you want to cancel this booking?",
                            style: TextStyle(
                              fontSize: _clamp(screenWidth * 0.04, 14, 22),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                "No",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: _clamp(screenWidth * 0.04, 14, 22),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                "Yes",
                                style: TextStyle(
                                  fontSize: _clamp(screenWidth * 0.04, 14, 22),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        _cancelBooking(booking);
                      }
                    },
                    icon: Icon(Icons.cancel, size: buttonIconSize),
                    label: Text(
                      "Cancel Booking",
                      style: TextStyle(fontSize: buttonFontSize),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: _clamp(screenWidth * 0.04, 12, 24),
                        vertical: _clamp(screenHeight * 0.01, 8, 16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_clamp(screenWidth * 0.025, 8, 16)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, double iconSize, double labelWidth, double fontSize) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: iconSize),
        SizedBox(width: iconSize * 0.6),
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: fontSize,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}