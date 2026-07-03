import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/presentation/screens/blood/donate.dart';
import 'package:hosta/providers/blood_details_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

class MyBloodDetailsPage extends ConsumerStatefulWidget {
  const MyBloodDetailsPage({super.key});

  @override
  ConsumerState<MyBloodDetailsPage> createState() => _MyBloodDetailsPageState();
}

class _MyBloodDetailsPageState extends ConsumerState<MyBloodDetailsPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDonor();
  }

  Future<void> _loadDonor() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      await ref.read(bloodProvider.notifier).fetchDonor(userId);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final donor = ref.watch(bloodProvider); // single donor map or null

    // Responsive clamped values
    final double appBarTitleSize = _clamp(screenWidth * 0.05, 16, 24);
    final double leadingIconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double progressStrokeWidth = _clamp(screenWidth * 0.008, 2, 6);
    final double cardMargin = _clamp(screenWidth * 0.04, 12, 32);
    final double cardPadding = _clamp(screenWidth * 0.04, 12, 32);
    final double cardRadius = _clamp(screenWidth * 0.04, 12, 24);
    final double iconSize = _clamp(screenWidth * 0.15, 60, 120);
    final double emptyTextSize = _clamp(screenWidth * 0.04, 14, 22);
    final double buttonPaddingH = _clamp(screenWidth * 0.06, 16, 48);
    final double buttonPaddingV = _clamp(screenHeight * 0.015, 8, 20);
    final double buttonRadius = _clamp(screenWidth * 0.03, 8, 30);
    final double buttonTextSize = _clamp(screenWidth * 0.035, 12, 20);
    final double donorCardMargin = _clamp(screenWidth * 0.04, 12, 32);
    final double donorCardPadding = _clamp(screenWidth * 0.04, 12, 32);
    final double bloodGroupFontSize = _clamp(screenWidth * 0.055, 20, 32);
    final double moreIconSize = _clamp(screenWidth * 0.06, 24, 40);
    final double detailFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double popupIconSize = _clamp(screenWidth * 0.05, 16, 24);
    final double popupTextSize = _clamp(screenWidth * 0.04, 14, 22);
    final double spacing = _clamp(screenHeight * 0.008, 6, 16);
    final double emptySpacing = _clamp(screenHeight * 0.0125, 8, 20);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Blood Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: appBarTitleSize,
          ),
        ),
        backgroundColor: Colors.red,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: leadingIconSize,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: progressStrokeWidth,
              ),
            )
          : donor == null
              ? _noDonorUI(context, screenWidth, screenHeight)
              : _donorCard(donor, screenWidth, screenHeight),
    );
  }

  Widget _noDonorUI(BuildContext context, double screenWidth, double screenHeight) {
    // Responsive clamped values for empty state
    final double cardMargin = _clamp(screenWidth * 0.04, 12, 32);
    final double cardRadius = _clamp(screenWidth * 0.05, 12, 24);
    final double cardPadding = _clamp(screenWidth * 0.05, 16, 40);
    final double iconSize = _clamp(screenWidth * 0.15, 60, 120);
    final double emptyTextSize = _clamp(screenWidth * 0.04, 14, 22);
    final double buttonPaddingH = _clamp(screenWidth * 0.06, 16, 48);
    final double buttonPaddingV = _clamp(screenHeight * 0.015, 8, 20);
    final double buttonRadius = _clamp(screenWidth * 0.03, 8, 30);
    final double buttonTextSize = _clamp(screenWidth * 0.035, 12, 20);
    final double spacing = _clamp(screenHeight * 0.0125, 8, 20);

    return Center(
      child: Card(
        margin: EdgeInsets.all(cardMargin),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bloodtype,
                size: iconSize,
                color: Colors.red,
              ),
              SizedBox(height: spacing),
              Text(
                "No Donor Profile Found",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: emptyTextSize,
                ),
              ),
              SizedBox(height: spacing),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Donate()),
                  );
                  if (result == true) _loadDonor();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: buttonPaddingH,
                    vertical: buttonPaddingV,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonRadius),
                  ),
                ),
                child: Text(
                  "Register as Donor",
                  style: TextStyle(fontSize: buttonTextSize),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _donorCard(Map<String, dynamic> donor, double screenWidth, double screenHeight) {
    final name = donor['name'] ?? 'Not specified';
    final dobRaw = donor['dateOfBirth'];
    final dateOfBirth = dobRaw != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dobRaw))
        : "Not specified";
    final bloodGroup = donor['bloodGroup'] ?? 'Not specified';
    final phone = donor['phone'] ?? 'Not available';
    final address = donor['address'] as Map<String, dynamic>?;
    final place = address?['place'] ?? '';
    final district = address?['district'] ?? '';
    final stateName = address?['state'] ?? '';
    final location = [place, district, stateName].where((s) => s.isNotEmpty).join(', ');
    final fullLocation = location.isEmpty ? 'Not provided' : location;

    // Responsive clamped values for donor card
    final double cardMargin = _clamp(screenWidth * 0.04, 12, 32);
    final double cardRadius = _clamp(screenWidth * 0.04, 12, 24);
    final double cardPadding = _clamp(screenWidth * 0.04, 12, 32);
    final double bloodGroupFontSize = _clamp(screenWidth * 0.055, 20, 32);
    final double moreIconSize = _clamp(screenWidth * 0.06, 24, 40);
    final double detailFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double popupIconSize = _clamp(screenWidth * 0.05, 16, 24);
    final double popupTextSize = _clamp(screenWidth * 0.04, 14, 22);
    final double spacing = _clamp(screenHeight * 0.008, 6, 16);

    return Padding(
      padding: EdgeInsets.all(cardMargin),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: Colors.grey),
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      bloodGroup,
                      style: TextStyle(
                        fontSize: bloodGroupFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: moreIconSize,
                    ),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Donate(editData: donor),
                          ),
                        );
                        if (result == true) _loadDonor();
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              "Delete Donor",
                              style: TextStyle(
                                fontSize: _clamp(screenWidth * 0.05, 18, 28),
                              ),
                            ),
                            content: Text(
                              "Are you sure you want to delete this donor record?",
                              style: TextStyle(
                                fontSize: _clamp(screenWidth * 0.04, 14, 22),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx, false);
                                },
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: _clamp(screenWidth * 0.04, 14, 22),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx, true);
                                },
                                child: Text(
                                  "Delete",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: _clamp(screenWidth * 0.04, 14, 22),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(bloodProvider.notifier).deleteDonor();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Donor deleted successfully"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadDonor(); // reload (will become null)
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: Colors.black,
                              size: popupIconSize,
                            ),
                            SizedBox(width: _clamp(screenWidth * 0.03, 8, 16)),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: popupTextSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              color: Colors.black,
                              size: popupIconSize,
                            ),
                            SizedBox(width: _clamp(screenWidth * 0.03, 8, 16)),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: popupTextSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Text(
                "Name : $name",
                style: TextStyle(
                  fontSize: detailFontSize,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "D.O.B : $dateOfBirth",
                style: TextStyle(
                  fontSize: detailFontSize,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Phone: $phone",
                style: TextStyle(
                  fontSize: detailFontSize,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Location: $fullLocation",
                style: TextStyle(
                  fontSize: detailFontSize,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}