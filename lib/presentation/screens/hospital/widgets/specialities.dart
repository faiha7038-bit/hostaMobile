import 'package:flutter/material.dart';
import 'package:hosta/services/api_service.dart';

class SpecialtiesTab extends StatefulWidget {
  final Map<String, dynamic> hospital;
  final Function(String, String) onSpecialtyTap;  // now passes hospitalId + department

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
      // Get hospitalId from hospital object (use 'hospitalId' or 'id')
      final hospitalId = widget.hospital['hospitalId'] ?? widget.hospital['id'];
      if (hospitalId == null) {
        print('❌ No hospital ID found');
        return {};
      }

      // Call your existing endpoint: /doctor?hospitalId=...
      final response = await _apiService.getDoctorsByHospital(hospitalId);
      List<dynamic> doctors = [];

      // Parse response (adjust based on your actual API structure)
      if (response.data is Map && response.data['data'] is List) {
        doctors = response.data['data'];
      } else if (response.data is List) {
        doctors = response.data;
      }

      // Group doctors by department
      Map<String, List<dynamic>> grouped = {};
      for (var doctor in doctors) {
        String department = doctor['department'] ?? 'Other';
        if (!grouped.containsKey(department)) {
          grouped[department] = [];
        }
        grouped[department]!.add(doctor);
      }
      return grouped;
    } catch (e) {
      print('❌ Error fetching doctors: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return FutureBuilder<Map<String, List<dynamic>>>(
      future: _specialtiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: screenWidth * 0.008,
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
                  size: screenWidth * 0.16,
                  color: Colors.grey,
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  "No specialties available",
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
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
          padding: EdgeInsets.all(screenWidth * 0.04),
          itemCount: specialtiesList.length,
          itemBuilder: (context, index) {
            final department = specialtiesList[index];
            final doctors = specialtiesMap[department]!;
            final doctorsCount = doctors.length;

            return Card(
              elevation: screenWidth * 0.0075,
              margin: EdgeInsets.only(bottom: screenHeight * 0.015),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              child: InkWell(
                onTap: () {
                  // Pass hospitalId and department to parent
                  final hospitalId = widget.hospital['hospitalId'] ?? widget.hospital['id'];
                  widget.onSpecialtyTap(hospitalId.toString(), department);
                },
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
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
                                fontSize: screenWidth * 0.04,
                                color: const Color.fromARGB(255, 12, 94, 15),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: screenWidth * 0.04,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.01),
                        child: Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              size: screenWidth * 0.035,
                              color: Colors.green,
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Text(
                              "$doctorsCount doctor${doctorsCount == 1 ? '' : 's'} available",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                                fontSize: screenWidth * 0.03,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenHeight * 0.0025,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              ),
                              child: Text(
                                "View Doctors",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: screenWidth * 0.025,
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