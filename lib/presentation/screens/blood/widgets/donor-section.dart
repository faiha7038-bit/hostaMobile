import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DonorSection extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> donors;
  final String searchQuery;
  final String selectedCountry;
  final String selectedState;
  final String selectedDistrict;
  final String selectedPlace;
  final String selectedBloodGroup;
  final VoidCallback onRefresh;
  final Function(String) onMakePhoneCall;
  final int Function(String) calculateAge;

  const DonorSection({
    super.key,
    required this.isLoading,
    required this.donors,
    required this.searchQuery,
    required this.selectedCountry,
    required this.selectedState,
    required this.selectedDistrict,
    required this.selectedPlace,
    required this.selectedBloodGroup,
    required this.onRefresh,
    required this.onMakePhoneCall,
    required this.calculateAge,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.red,
              strokeWidth: screenWidth * 0.008,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              "Loading donors...",
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final filteredDonors = _getFilteredDonors();

    if (filteredDonors.isEmpty) {
      return _buildEmptyState(screenWidth, screenHeight);
    }

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.03),
      itemCount: filteredDonors.length,
      itemBuilder: (context, index) {
        return _buildDonorCard(
          filteredDonors[index],
          screenWidth,
          screenHeight,
        );
      },
    );
  }

  List<dynamic> _getFilteredDonors() {
    final filtered = donors.where((donor) {
      // ✅ donor is a Map; userId is an int, not a Map
      final address = donor['address'] ?? {};

      final donorId = (donor['donorId'] ?? '').toString().toLowerCase();
      final phone = (donor['phone'] ?? '').toString().toLowerCase();
      final bloodGroup = (donor['bloodGroup'] ?? '').toString();
      final country = (address['country'] ?? '').toString().trim();
      final state = (address['state'] ?? '').toString().trim();
      final district = (address['district'] ?? '').toString().trim();
      final place = (address['place'] ?? '').toString().trim();

      // Search query matches donorId or phone (since no name field)
      final matchesSearch = searchQuery.isEmpty ||
          donorId.contains(searchQuery.toLowerCase()) ||
          phone.contains(searchQuery.toLowerCase());

      final matchesCountry =
          selectedCountry.isEmpty || country == selectedCountry;
      final matchesState = selectedState.isEmpty || state == selectedState;
      final matchesDistrict =
          selectedDistrict.isEmpty || district == selectedDistrict;
      final matchesPlace = selectedPlace.isEmpty || place == selectedPlace;
      final matchesBlood =
          selectedBloodGroup.isEmpty ||
          selectedBloodGroup == "All" ||
          bloodGroup == selectedBloodGroup;

      return matchesSearch &&
          matchesCountry &&
          matchesState &&
          matchesDistrict &&
          matchesPlace &&
          matchesBlood;
    }).toList();

    return filtered;
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            donors.isEmpty ? Icons.error_outline : Icons.search_off,
            size: screenWidth * 0.15,
            color: Colors.grey,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            donors.isEmpty ? "No donors available" : "No donors found",
            style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            donors.isEmpty
                ? "Check your connection or try again later"
                : "Try adjusting your filters",
            style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (donors.isEmpty) ...[
            SizedBox(height: screenHeight * 0.025),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.015,
                ),
              ),
              child: Text(
                "Try Again",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonorCard(
    Map<String, dynamic> donor,
    double screenWidth,
    double screenHeight,
  ) {
    final address = donor['address'] ?? {};
    final phone = donor['phone'] ?? '';
    final dateOfBirth = donor['dateOfBirth']?.toString() ?? '';
    final age = dateOfBirth.isNotEmpty ? calculateAge(dateOfBirth) : 0;
    final donorId = donor['donorId'] ?? 'Unknown';
    final bloodGroup = donor['bloodGroup'] ?? '?';

    // Display name is missing – show donorId instead
    final displayName = 'Donor $donorId';

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Row(
        children: [
          // Blood Group Circle
          Container(
            width: screenWidth * 0.1375,
            height: screenWidth * 0.1375,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              bloodGroup,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenHeight * 0.0025),
                if (age > 0)
                  Text(
                    "$age years",
                    style: TextStyle(
                      fontSize: screenWidth * 0.0325,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                SizedBox(height: screenHeight * 0.005),
                if (address['place'] != null && address['place'].toString().isNotEmpty)
                  Text(
                    address['place'],
                    style: TextStyle(
                      fontSize: screenWidth * 0.0325,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: screenHeight * 0.0025),
                Text(
                  "${address['district'] ?? ''} ${address['state'] ?? ''} ${address['country'] ?? ''}".trim(),
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: phone.toString().isNotEmpty
                ? () => onMakePhoneCall(phone.toString())
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.0125,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
            ),
            icon: Icon(
              Icons.call,
              size: screenWidth * 0.045,
              color: Colors.white,
            ),
            label: Text(
              "Call",
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ),
        ],
      ),
    );
  }
}