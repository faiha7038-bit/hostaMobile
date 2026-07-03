import 'package:flutter/material.dart';
import 'package:hosta/services/api_service.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

class SpecialtiesTab extends StatefulWidget {
  final Map<String, dynamic> hospital;
  final Function(String, String) onSpecialtyTap; // now passes hospitalId + department

  const SpecialtiesTab({
    super.key,
    required this.hospital,
    required this.onSpecialtyTap,
  });

  @override
  State<SpecialtiesTab> createState() => _SpecialtiesTabState();
}

class _SpecialtiesTabState extends State<SpecialtiesTab> {
  late Future<Map<String, List<dynamic>>> _specialtiesFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _specialtiesFuture = _fetchDoctorsGroupedByDepartment();
  }

  Future<Map<String, List<dynamic>>> _fetchDoctorsGroupedByDepartment() async {
    try {
      // ✅ FIX: extract numeric ID only
      final numericId = widget.hospital['id'] ?? widget.hospital['hospitalId'];
      if (numericId == null) {
        return {};
      }
      final hospitalId = numericId is int ? numericId.toString() :
                         (numericId is String && int.tryParse(numericId) != null) ? numericId : null;
      if (hospitalId == null) {
        return {};
      }

      final response = await _apiService.getDoctors(hospitalId: hospitalId);

      List<dynamic> doctors = [];
      if (response.data is Map && response.data['data'] is List) {
        doctors = response.data['data'];
      } else if (response.data is List) {
        doctors = response.data;
      }

      Map<String, List<dynamic>> grouped = {};

      for (var doctor in doctors) {
        String department =
            (doctor['department'] ?? 'Other').toString().trim();
        // case-insensitive key
        String key = department.toLowerCase();
        grouped.putIfAbsent(key, () => []).add(doctor);
      }

      return grouped;
    } catch (e, stack) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive clamped values
    final double loadingStrokeWidth = _clamp(screenWidth * 0.008, 2, 6);
    final double emptyIconSize = _clamp(screenWidth * 0.16, 50, 100);
    final double emptyFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double listPadding = _clamp(screenWidth * 0.04, 12, 24);
    final double cardElevation = _clamp(screenWidth * 0.0075, 2, 8);
    final double cardMarginBottom = _clamp(screenHeight * 0.015, 8, 20);
    final double cardRadius = _clamp(screenWidth * 0.03, 8, 18);
    final double cardPadding = _clamp(screenWidth * 0.04, 12, 24);
    final double departmentFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double arrowIconSize = _clamp(screenWidth * 0.04, 14, 22);
    final double medicalIconSize = _clamp(screenWidth * 0.035, 12, 20);
    final double countFontSize = _clamp(screenWidth * 0.03, 10, 16);
    final double viewDoctorsPaddingH = _clamp(screenWidth * 0.02, 6, 16);
    final double viewDoctorsPaddingV = _clamp(screenHeight * 0.0025, 2, 6);
    final double viewDoctorsRadius = _clamp(screenWidth * 0.03, 8, 18);
    final double viewDoctorsFontSize = _clamp(screenWidth * 0.025, 8, 14);
    final double spacing = _clamp(screenHeight * 0.02, 12, 24);
    final double spacingSmall = _clamp(screenHeight * 0.01, 6, 16);
    final double spacingTiny = _clamp(screenWidth * 0.01, 4, 12);

    return FutureBuilder<Map<String, List<dynamic>>>(
      future: _specialtiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: loadingStrokeWidth,
              color: Colors.green,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: emptyIconSize,
                  color: Colors.grey,
                ),
                SizedBox(height: spacing),
                Text(
                  "No specialties available",
                  style: TextStyle(
                    fontSize: emptyFontSize,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final specialtiesMap = snapshot.data!;
        final specialtiesList = specialtiesMap.keys.toList();

        return ListView.builder(
          padding: EdgeInsets.all(listPadding),
          itemCount: specialtiesList.length,
          itemBuilder: (context, index) {
            final department = specialtiesList[index].toUpperCase();
            final doctors = specialtiesMap[specialtiesList[index]]!;
            final doctorsCount = doctors.length;

            return Card(
              elevation: cardElevation,
              margin: EdgeInsets.only(bottom: cardMarginBottom),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cardRadius),
              ),
              child: InkWell(
                onTap: () {
                  // ✅ Always use numeric 'id' field
                  final hospitalId = widget.hospital['id'];
                  if (hospitalId == null) {
                    return;
                  }
                  widget.onSpecialtyTap(hospitalId.toString(), department);
                },
                borderRadius: BorderRadius.circular(cardRadius),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              department,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: departmentFontSize,
                                color: const Color.fromARGB(255, 12, 94, 15),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: arrowIconSize,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: spacingSmall),
                        child: Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              size: medicalIconSize,
                              color: Colors.green,
                            ),
                            SizedBox(width: spacingTiny),
                            Text(
                              "$doctorsCount doctor${doctorsCount == 1 ? '' : 's'} available",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                                fontSize: countFontSize,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: viewDoctorsPaddingH,
                                vertical: viewDoctorsPaddingV,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(
                                  viewDoctorsRadius,
                                ),
                              ),
                              child: Text(
                                "View Doctors",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: viewDoctorsFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}