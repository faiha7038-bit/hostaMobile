import 'package:flutter/material.dart';

class DonorSection extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> donors;
  final String searchQuery;
  final VoidCallback onRefresh;
  final Function(String) onMakePhoneCall;
  final int Function(String) calculateAge;

  const DonorSection({
    super.key,
    required this.isLoading,
    required this.donors,
    required this.searchQuery,
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
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: screenHeight * 0.02),
            Text("Loading donors...", style: TextStyle(fontSize: screenWidth * 0.04)),
          ],
        ),
      );
    }

    // final filteredDonors = _getFilteredDonors();
    final filteredDonors = donors;

    if (filteredDonors.isEmpty) {
      return _buildEmptyState(screenWidth, screenHeight);
    }

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.03),
      itemCount: filteredDonors.length,
      itemBuilder: (context, index) => _buildDonorCard(filteredDonors[index], screenWidth, screenHeight),
    );
  }



  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(donors.isEmpty ? Icons.error_outline : Icons.search_off,
              size: screenWidth * 0.15, color: Colors.grey),
          SizedBox(height: screenHeight * 0.02),
          Text(donors.isEmpty ? "No donors available" : "No donors found",
              style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey)),
          if (donors.isEmpty) ...[
            SizedBox(height: screenHeight * 0.025),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Try Again", style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonorCard(Map<String, dynamic> donor, double screenWidth, double screenHeight) {
    final address = donor['address'] ?? {};
    final phone = donor['phone'] ?? '';
    final dateOfBirth = donor['dateOfBirth']?.toString() ?? '';
    final age = dateOfBirth.isNotEmpty ? calculateAge(dateOfBirth) : 0;
   final donorId = donor['name'] ?? 'Unknown';
    final bloodGroup = donor['bloodGroup'] ?? '?';
    final displayName = ' $donorId';

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
          Container(
            width: screenWidth * 0.1375,
            height: screenWidth * 0.1375,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(bloodGroup, style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
                if (age > 0) Text("$age years", style: TextStyle(fontSize: screenWidth * 0.0325, color: Colors.black54)),
                if (address['place'] != null && address['place'].toString().isNotEmpty)
                  Text(address['place'], style: TextStyle(fontSize: screenWidth * 0.0325, color: Colors.black54)),
                Text("${address['district'] ?? ''} ${address['state'] ?? ''} ${address['country'] ?? ''}".trim(),
                    style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.black45)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: phone.toString().isNotEmpty ? () => onMakePhoneCall(phone.toString()) : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            icon: Icon(Icons.call, size: screenWidth * 0.045, color: Colors.white),
            label: Text("Call", style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.035)),
          ),
        ],
      ),
    );
  }
}