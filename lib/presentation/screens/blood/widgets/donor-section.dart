import 'package:flutter/material.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

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

    // Responsive clamped values
    final double loadingIndicatorSize = _clamp(screenWidth * 0.08, 24, 48);
    final double loadingTextSize = _clamp(screenWidth * 0.04, 14, 22);
    final double emptyIconSize = _clamp(screenWidth * 0.15, 60, 120);
    final double emptyTextSize = _clamp(screenWidth * 0.04, 14, 22);
    final double listPadding = _clamp(screenWidth * 0.03, 8, 20);
    final double cardMarginBottom = _clamp(screenHeight * 0.015, 8, 20);
    final double cardPadding = _clamp(screenWidth * 0.03, 10, 24);
    final double cardRadius = _clamp(screenWidth * 0.035, 10, 24);
    final double avatarSize = _clamp(screenWidth * 0.1375, 44, 80);
    final double avatarTextSize = _clamp(screenWidth * 0.04, 14, 24);
    final double nameFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double detailFontSize = _clamp(screenWidth * 0.0325, 12, 18);
    final double smallDetailFontSize = _clamp(screenWidth * 0.03, 11, 16);
    final double callIconSize = _clamp(screenWidth * 0.045, 16, 28);
    final double callLabelSize = _clamp(screenWidth * 0.035, 12, 18);
    final double spacing = _clamp(screenHeight * 0.02, 12, 30);
    final double smallSpacing = _clamp(screenHeight * 0.025, 16, 40);

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.red,
              strokeWidth: _clamp(screenWidth * 0.008, 2, 6),
            ),
            SizedBox(height: spacing),
            Text(
              "Loading donors...",
              style: TextStyle(fontSize: loadingTextSize),
            ),
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
      padding: EdgeInsets.all(listPadding),
      itemCount: filteredDonors.length,
      itemBuilder: (context, index) =>
          _buildDonorCard(filteredDonors[index], screenWidth, screenHeight),
    );
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    final double emptyIconSize = _clamp(screenWidth * 0.15, 60, 120);
    final double emptyTextSize = _clamp(screenWidth * 0.04, 14, 22);
    final double spacing = _clamp(screenHeight * 0.02, 12, 30);
    final double buttonSpacing = _clamp(screenHeight * 0.025, 16, 40);
    final double buttonFontSize = _clamp(screenWidth * 0.035, 14, 20);
    final double buttonPaddingH = _clamp(screenWidth * 0.06, 16, 40);
    final double buttonPaddingV = _clamp(screenHeight * 0.015, 8, 20);
    final double buttonRadius = _clamp(screenWidth * 0.03, 8, 16);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            donors.isEmpty ? Icons.error_outline : Icons.search_off,
            size: emptyIconSize,
            color: Colors.grey,
          ),
          SizedBox(height: spacing),
          Text(
            donors.isEmpty ? "No donors available" : "No donors found",
            style: TextStyle(fontSize: emptyTextSize, color: Colors.grey),
          ),
          if (donors.isEmpty) ...[
            SizedBox(height: buttonSpacing),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(
                  horizontal: buttonPaddingH,
                  vertical: buttonPaddingV,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonRadius),
                ),
              ),
              child: Text(
                "Try Again",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: buttonFontSize,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonorCard(
      Map<String, dynamic> donor, double screenWidth, double screenHeight) {
    final address = donor['address'] ?? {};
    final phone = donor['phone'] ?? '';
    final dateOfBirth = donor['dateOfBirth']?.toString() ?? '';
    final age = dateOfBirth.isNotEmpty ? calculateAge(dateOfBirth) : 0;
    final donorId = donor['name'] ?? 'Unknown';
    final bloodGroup = donor['bloodGroup'] ?? '?';
    final displayName = ' $donorId';

    // Clamped values for this card
    final double cardMarginBottom = _clamp(screenHeight * 0.015, 8, 20);
    final double cardPadding = _clamp(screenWidth * 0.03, 10, 24);
    final double cardRadius = _clamp(screenWidth * 0.035, 10, 24);
    final double avatarSize = _clamp(screenWidth * 0.1375, 44, 80);
    final double avatarTextSize = _clamp(screenWidth * 0.04, 14, 24);
    final double nameFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double detailFontSize = _clamp(screenWidth * 0.0325, 12, 18);
    final double smallDetailFontSize = _clamp(screenWidth * 0.03, 11, 16);
    final double callIconSize = _clamp(screenWidth * 0.045, 16, 28);
    final double callLabelSize = _clamp(screenWidth * 0.035, 12, 18);
    final double spacing = _clamp(screenWidth * 0.03, 8, 20);

    return Container(
      margin: EdgeInsets.only(bottom: cardMarginBottom),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              bloodGroup,
              style: TextStyle(
                color: Colors.white,
                fontSize: avatarTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (age > 0)
                  Text(
                    "$age years",
                    style: TextStyle(
                      fontSize: detailFontSize,
                      color: Colors.black54,
                    ),
                  ),
                if (address['place'] != null &&
                    address['place'].toString().isNotEmpty)
                  Text(
                    address['place'],
                    style: TextStyle(
                      fontSize: detailFontSize,
                      color: Colors.black54,
                    ),
                  ),
                Text(
                  "${address['district'] ?? ''} ${address['state'] ?? ''} ${address['country'] ?? ''}"
                      .trim(),
                  style: TextStyle(
                    fontSize: smallDetailFontSize,
                    color: Colors.black45,
                  ),
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
                horizontal: _clamp(screenWidth * 0.02, 6, 16),
                vertical: _clamp(screenHeight * 0.012, 6, 16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(_clamp(screenWidth * 0.025, 6, 16)),
              ),
            ),
            icon: Icon(
              Icons.call,
              size: callIconSize,
              color: Colors.white,
            ),
            label: Text(
              "Call",
              style: TextStyle(
                color: Colors.white,
                fontSize: callLabelSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
