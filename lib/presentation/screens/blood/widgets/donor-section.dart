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
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text(
              "Loading donors...",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final filteredDonors = _getFilteredDonors();

    if (filteredDonors.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredDonors.length,
      itemBuilder: (context, index) {
        return _buildDonorCard(filteredDonors[index]);
      },
    );
  }

  List<dynamic> _getFilteredDonors() {
    return donors.where((donor) {
      final user = donor['userId'] ?? {};
      final address = donor['address'] ?? {};

      final name = (user['name'] ?? '').toLowerCase();
      final bloodGroup = (donor['bloodGroup'] ?? '');
      final country = (address['country'] ?? '');
      final state = (address['state'] ?? '');
      final district = (address['district'] ?? '');
      final place = (address['place'] ?? '');

      final matchesSearch = name.contains(searchQuery.toLowerCase());
      final matchesCountry = selectedCountry.isEmpty || country == selectedCountry;
      final matchesState = selectedState.isEmpty || state == selectedState;
      final matchesDistrict = selectedDistrict.isEmpty || district == selectedDistrict;
      final matchesPlace = selectedPlace.isEmpty || place == selectedPlace;
      final matchesBlood = selectedBloodGroup.isEmpty ||
          selectedBloodGroup == "All" ||
          bloodGroup == selectedBloodGroup;

      return matchesSearch &&
          matchesCountry &&
          matchesState &&
          matchesDistrict &&
          matchesPlace &&
          matchesBlood;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            donors.isEmpty ? Icons.error_outline : Icons.search_off,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            donors.isEmpty ? "No donors available" : "No donors found",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            donors.isEmpty
                ? "Check your connection or try again later"
                : "Try adjusting your filters",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (donors.isEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                "Try Again",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonorCard(Map<String, dynamic> donor) {
    final user = donor['userId'] ?? {};
    final address = donor['address'] ?? {};
    
    final dateOfBirth = donor['dateOfBirth']?.toString() ?? '';
    final age = dateOfBirth.isNotEmpty ? calculateAge(dateOfBirth) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Row(
        children: [
          // Blood Group Circle
          Container(
            width: 55,
            height: 55,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              donor["bloodGroup"] ?? "",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user["name"] ?? "Unknown",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (age > 0)
                  Text(
                    "$age years",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  address["place"] ?? "",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${address["district"] ?? ""}, ${address["state"] ?? ""}, ${address["country"] ?? ""}",
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => onMakePhoneCall(user["phone"] ?? ""),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.call, size: 18, color: Colors.white),
            label: const Text("Call", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}