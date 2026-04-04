import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/doctor/doctors.dart';
import '../../../services/api_service.dart';

class Specialties extends StatefulWidget {
  const Specialties({super.key});

  @override
  State<Specialties> createState() => _SpecialitesState();
}

class _SpecialitesState extends State<Specialties> {
  String searchQuery = '';
  bool isLoading = false;
  bool isLoadingSpecialties = true; // For loading specialties
  List<dynamic> hospitalList = [];
  List<dynamic> specialtiesList = []; // To store specialties from API

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchSpecialties();
  }

  // Fetch specialties from API
  Future<void> _fetchSpecialties() async {
    try {
      setState(() {
        isLoadingSpecialties = true;
      });

      final response = await _apiService.getAllSpecility();
      
      if (response.statusCode == 200 && response.data != null) {
        // Handle different response formats
        dynamic specialtyData;
        
        if (response.data is Map) {
          // If response is a map, check for common keys
          if (response.data['specialties'] != null) {
            specialtyData = response.data['specialties'];
          } else if (response.data['data'] != null) {
            specialtyData = response.data['data'];
          } else {
            // If no specific key, use the entire response as list
            specialtyData = response.data is List ? response.data : [];
          }
        } else if (response.data is List) {
          specialtyData = response.data;
        } else {
          specialtyData = [];
        }
        
        final specialtyList = specialtyData is List ? specialtyData : [];
        
        setState(() {
          specialtiesList = specialtyList;
        });
        
        print("✅ Loaded ${specialtyList.length} specialties from API");
      } else {
        setState(() {
          specialtiesList = [];
        });
        print("❌ Failed to load specialties: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error loading specialties: $e");
      print("❌ Error type: ${e.runtimeType}");
      setState(() {
        specialtiesList = [];
      });
    } finally {
      setState(() {
        isLoadingSpecialties = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // 🔍 Filter specialties from API data
    final filteredData = specialtiesList.where((specialty) {
      final name = (specialty['name'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Medical Specialties",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchSpecialties,
            tooltip: 'Refresh',
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ===== Search Box =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search specialties...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ===== Grid =====
            if (isLoadingSpecialties)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        "Loading specialties...",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (specialtiesList.isEmpty && !isLoadingSpecialties)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No specialties available",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Check your connection or try again later",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1, // Increased for better text fit
                      ),
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        final specialty = filteredData[index];
                        final name = specialty['name']?.toString() ?? 'Unknown';
                        final picture = specialty['picture'] ?? {};
                        final imageUrl = picture['imageUrl']?.toString() ?? '';
                        
                        return GestureDetector(
                          onTap: () => _fetchAndShowHospitals(context, name),
                          child: _buildCard(name, imageUrl, width),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String name, String imageUrl, double width) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Specialty Image
          if (imageUrl.isNotEmpty)
            Container(
              width: width * 0.22,
              height: width * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.green,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.medical_services,
                      size: width * 0.18,
                      color: Colors.green,
                    );
                  },
                ),
              ),
            )
          else
            Container(
              width: width * 0.22,
              height: width * 0.22,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Icon(
                Icons.medical_services,
                size: width * 0.18,
                color: Colors.green,
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Specialty Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              name[0].toUpperCase() + name.substring(1),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ===== Fetch Hospitals from API and Show Popup =====
  Future<void> _fetchAndShowHospitals(BuildContext context, String specialtyName) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _apiService.getAllHospitalsSpeciality(specialtyName);
      
      if (response.statusCode == 200 && response.data != null) {
        // Handle different response formats
        dynamic hospitalData;
        
        if (response.data is Map) {
          // If response is a map, check for common keys
          if (response.data['hospitals'] != null) {
            hospitalData = response.data['hospitals'];
          } else if (response.data['data'] != null) {
            hospitalData = response.data['data'];
          } else {
            // If no specific key, use the entire response as list
            hospitalData = response.data is List ? response.data : [];
          }
        } else if (response.data is List) {
          hospitalData = response.data;
        } else {
          hospitalData = [];
        }
        
        final hospitalListData = hospitalData is List ? hospitalData : [];
        
        setState(() {
          hospitalList = hospitalListData;
        });
        
        print("✅ Loaded ${hospitalListData.length} hospitals for $specialtyName");
        _showHospitalPopup(context, specialtyName);
      } else {
        setState(() {
          hospitalList = [];
        });
        _showErrorSnackbar(context, "Failed to load hospitals");
        print("❌ Failed to load hospitals: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching hospitals: $e");
      setState(() {
        hospitalList = [];
      });
      _showErrorSnackbar(context, "Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ===== Filter hospitals by specialty =====
  List<dynamic> _filterHospitalsBySpecialty(String specialtyName) {
    return hospitalList.where((hospital) {
      final specialties = hospital['specialties'] as List? ?? [];
      return specialties.any((specialty) => 
        (specialty['name'] as String?)?.toLowerCase().contains(specialtyName.toLowerCase()) ?? false
      );
    }).toList();
  }

  // ===== Get total doctors count for a hospital in specific specialty =====
  int _getDoctorsCountForSpecialty(Map<String, dynamic> hospital, String specialtyName) {
    try {
      final specialties = hospital['specialties'] as List? ?? [];
      for (var specialty in specialties) {
        final specialtyMap = specialty as Map<String, dynamic>;
        if ((specialtyMap['name'] as String?)?.toLowerCase().contains(specialtyName.toLowerCase()) ?? false) {
          final doctors = specialtyMap['doctors'] as List? ?? [];
          return doctors.length;
        }
      }
      return 0;
    } catch (e) {
      print("Error getting doctors count: $e");
      return 0;
    }
  }

  // ===== Get all doctors count for hospital =====
  int _getTotalDoctorsCount(Map<String, dynamic> hospital) {
    try {
      final specialties = hospital['specialties'] as List? ?? [];
      int totalDoctors = 0;
      for (var specialty in specialties) {
        final specialtyMap = specialty as Map<String, dynamic>;
        final doctors = specialtyMap['doctors'] as List? ?? [];
        totalDoctors += doctors.length;
      }
      return totalDoctors;
    } catch (e) {
      print("Error getting total doctors count: $e");
      return 0;
    }
  }

  // ===== Navigate to Doctors Page =====
  void _navigateToDoctorsPage(BuildContext context, String hospitalId, String specialtyName, String hospitalName) {
    // Close the bottom sheet first
    Navigator.pop(context);
    
    // Then navigate to doctors page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Doctors(
          hospitalId: hospitalId,
          specialty: specialtyName,
        ),
      ),
    );
  }

  // ===== Bottom Sheet Popup with API Data =====
  void _showHospitalPopup(BuildContext context, String specialtyName) {
    final filteredHospitals = _filterHospitalsBySpecialty(specialtyName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              child: Column(
                children: [
                  // --- Header with Close Button ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Wrap specialty name in Expanded to prevent overflow
                        Expanded(
                          child: Text(
                            "${specialtyName.toUpperCase()} HOSPITALS",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // --- Hospital Count ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "Found ${filteredHospitals.length} hospitals",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // --- Loading Indicator ---
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  else if (filteredHospitals.isEmpty)
                    // --- No Hospitals Found ---
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_hospital_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No hospitals found",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "for this specialty",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // --- Scrollable Hospital List ---
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredHospitals.length,
                        itemBuilder: (context, index) {
                          final hospital = filteredHospitals[index];
                          return _buildHospitalCard(context, hospital, specialtyName);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===== Build Hospital Card from API Data =====
  Widget _buildHospitalCard(BuildContext context, Map<String, dynamic> hospital, String specialtyName) {
    final imageUrl = (hospital['image'] as Map<String, dynamic>?)?['imageUrl'] as String? ?? '';
    final hospitalName = hospital['name'] as String? ?? 'Unknown Hospital';
    final address = hospital['address'] as String? ?? '';
    final phone = hospital['phone'] as String? ?? '';
    final hospitalId = hospital['_id'] as String? ?? '';
    
    final specialtyDoctorsCount = _getDoctorsCountForSpecialty(hospital, specialtyName);
    final totalDoctorsCount = _getTotalDoctorsCount(hospital);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (hospitalId.isNotEmpty) {
            _navigateToDoctorsPage(context, hospitalId, specialtyName, hospitalName);
          } else {
            _showErrorSnackbar(context, "Hospital ID not available");
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hospital Avatar
              _buildHospitalAvatar(imageUrl),
              const SizedBox(width: 12),
              
              // Hospital Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hospital Name
                    Text(
                      hospitalName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    
                    // Specialty Doctors Count
                    Row(
                      children: [
                        Icon(Icons.medical_services, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "$specialtyDoctorsCount $specialtyName doctors",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    
                    // Total Doctors Count
                    Row(
                      children: [
                        Icon(Icons.people_alt_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          "$totalDoctorsCount total doctors",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Address
                    if (address.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    
                    // Phone
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Forward Arrow
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Build Hospital Avatar with proper error handling =====
  Widget _buildHospitalAvatar(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.blue[100],
                child: const Center(
                  child: Icon(Icons.local_hospital, size: 24, color: Colors.green),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.green[100],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Icon(Icons.local_hospital, size: 24, color: Colors.green),
        ),
      );
    }
  }
}