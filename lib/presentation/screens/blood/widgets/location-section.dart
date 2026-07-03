import 'package:flutter/material.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

class LocationSection extends StatelessWidget {
  final String selectedCountry;
  final String selectedState;
  final String selectedDistrict;
  final String selectedPlace;
  final List<String> countries;
  final List<String> states;
  final List<String> districts;
  final List<String> places;
  final List<dynamic> donors;
  final Function(String, String, String, String) onLocationSelected;
  final VoidCallback onClear;

  const LocationSection({
    super.key,
    required this.selectedCountry,
    required this.selectedState,
    required this.selectedDistrict,
    required this.selectedPlace,
    required this.countries,
    required this.states,
    required this.districts,
    required this.places,
    required this.donors,
    required this.onLocationSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive clamped values
    final double horizontalPadding = _clamp(screenWidth * 0.04, 12, 32);
    final double verticalPadding = _clamp(screenHeight * 0.005, 4, 12);
    final double containerPaddingH = _clamp(screenWidth * 0.03, 8, 24);
    final double containerPaddingV = _clamp(screenHeight * 0.0125, 8, 20);
    final double containerRadius = _clamp(screenWidth * 0.025, 8, 16);
    final double displayFontSize = _clamp(screenWidth * 0.035, 12, 20);
    final double clearIconSize = _clamp(screenWidth * 0.05, 20, 32);
    final double clearLabelSize = _clamp(screenWidth * 0.035, 12, 20);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _openLocationFilter(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: containerPaddingH,
                  vertical: containerPaddingV,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(containerRadius),
                ),
                child: Text(
                  _getDisplayText(),
                  style: TextStyle(
                    fontSize: displayFontSize,
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onClear,
            icon: Icon(
              Icons.clear,
              color: Colors.red,
              size: clearIconSize,
            ),
            label: Text(
              "Clear",
              style: TextStyle(
                color: Colors.red,
                fontSize: clearLabelSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayText() {
    if (selectedCountry.isEmpty &&
        selectedState.isEmpty &&
        selectedDistrict.isEmpty &&
        selectedPlace.isEmpty) {
      return "Select Location";
    }
    final parts = <String>[];
    if (selectedCountry.isNotEmpty) parts.add(selectedCountry);
    if (selectedState.isNotEmpty) parts.add(selectedState);
    if (selectedDistrict.isNotEmpty) parts.add(selectedDistrict);
    if (selectedPlace.isNotEmpty) parts.add(selectedPlace);
    return parts.join(" > ");
  }

  void _openLocationFilter(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive clamped values for bottom sheet
    final double sheetRadius = _clamp(screenWidth * 0.05, 20, 40);
    final double sheetPaddingH = _clamp(screenWidth * 0.04, 12, 32);
    final double sheetPaddingTop = _clamp(screenHeight * 0.02, 12, 32);
    final double sheetPaddingBottom = _clamp(screenHeight * 0.02, 12, 32);
    final double titleFontSize = _clamp(screenWidth * 0.045, 18, 28);
    final double dividerThickness = _clamp(screenWidth * 0.0025, 0.5, 2);
    final double labelFontSize = _clamp(screenWidth * 0.035, 12, 20);
    final double dropdownRadius = _clamp(screenWidth * 0.025, 8, 16);
    final double dropdownPaddingH = _clamp(screenWidth * 0.03, 8, 20);
    final double dropdownPaddingV = _clamp(screenHeight * 0.015, 8, 20);
    final double spacing = _clamp(screenHeight * 0.02, 12, 28);
    final double spacingLarge = _clamp(screenHeight * 0.03, 20, 40);
    final double buttonPaddingV = _clamp(screenHeight * 0.02, 12, 32);
    final double buttonRadius = _clamp(screenWidth * 0.03, 10, 20);
    final double buttonFontSize = _clamp(screenWidth * 0.04, 14, 24);
    final double dropdownItemFontSize = _clamp(screenWidth * 0.035, 12, 20);

    String tempCountry = selectedCountry;
    String tempState = selectedState;
    String tempDistrict = selectedDistrict;
    String tempPlace = selectedPlace;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                sheetPaddingH,
                sheetPaddingTop,
                sheetPaddingH,
                MediaQuery.of(context).viewInsets.bottom + sheetPaddingBottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        "Select Location",
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing),
                    Divider(thickness: dividerThickness),

                    // Country Dropdown
                    DropdownButtonFormField<String>(
                      value: tempCountry.isEmpty ? null : tempCountry,
                      decoration: InputDecoration(
                        labelText: "Country",
                        labelStyle: TextStyle(fontSize: labelFontSize),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(dropdownRadius),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: dropdownPaddingH,
                          vertical: dropdownPaddingV,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text("Any Country"),
                        ),
                        ...countries.map(
                          (country) => DropdownMenuItem(
                            value: country,
                            child: Text(
                              country,
                              style: TextStyle(fontSize: dropdownItemFontSize),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => tempCountry = value ?? ''),
                    ),
                    SizedBox(height: spacing),

                    // State Dropdown (independent)
                    DropdownButtonFormField<String>(
                      value: tempState.isEmpty ? null : tempState,
                      decoration: InputDecoration(
                        labelText: "State",
                        labelStyle: TextStyle(fontSize: labelFontSize),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(dropdownRadius),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: dropdownPaddingH,
                          vertical: dropdownPaddingV,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text("Any State"),
                        ),
                        ...states.map(
                          (state) => DropdownMenuItem(
                            value: state,
                            child: Text(
                              state,
                              style: TextStyle(fontSize: dropdownItemFontSize),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => tempState = value ?? ''),
                    ),
                    SizedBox(height: spacing),

                    // District Dropdown (independent)
                    DropdownButtonFormField<String>(
                      value: tempDistrict.isEmpty ? null : tempDistrict,
                      decoration: InputDecoration(
                        labelText: "District",
                        labelStyle: TextStyle(fontSize: labelFontSize),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(dropdownRadius),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: dropdownPaddingH,
                          vertical: dropdownPaddingV,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text("Any District"),
                        ),
                        ...districts.map(
                          (district) => DropdownMenuItem(
                            value: district,
                            child: Text(
                              district,
                              style: TextStyle(fontSize: dropdownItemFontSize),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => tempDistrict = value ?? ''),
                    ),
                    SizedBox(height: spacing),

                    // Place Dropdown (independent)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: tempPlace.isEmpty ? null : tempPlace,
                      decoration: InputDecoration(
                        labelText: "Place",
                        labelStyle: TextStyle(fontSize: labelFontSize),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(dropdownRadius),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: dropdownPaddingH,
                          vertical: dropdownPaddingV,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text("Any Place"),
                        ),
                        ...places.map(
                          (place) => DropdownMenuItem(
                            value: place,
                            child: Text(
                              place,
                              style: TextStyle(fontSize: dropdownItemFontSize),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => tempPlace = value ?? ''),
                    ),
                    SizedBox(height: spacingLarge),

                    // Apply Filter Button
                    ElevatedButton(
                      onPressed: () {
                        onLocationSelected(
                            tempCountry, tempState, tempDistrict, tempPlace);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: buttonPaddingV),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(buttonRadius),
                        ),
                      ),
                      child: Text(
                        "Apply Filter",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: buttonFontSize,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}