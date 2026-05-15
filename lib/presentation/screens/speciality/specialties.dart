import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/specialities-provider.dart';

class Specialties extends ConsumerStatefulWidget {
  const Specialties({super.key});

  @override
  ConsumerState<Specialties> createState() => _SpecialitesState();
}

class _SpecialitesState extends ConsumerState<Specialties> {
  @override
  void initState() {
    super.initState();
    // Trigger specialties fetch
    ref.read(specialtiesProvider);
  }

  void _showErrorSnackbar(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: screenWidth * 0.04),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final searchQuery = ref.watch(searchQueryProvider);
    final filteredSpecialties = ref.watch(filteredSpecialtiesProvider);
    final specialtiesAsync = ref.watch(specialtiesProvider);
    final hospitalsLoading = ref.watch(hospitalsLoadingProvider);
    final hospitalsForSpecialty = ref.watch(hospitalsForSpecialtyProvider);
    final selectedSpecialty = ref.watch(selectedSpecialtyProvider);
    final hospitalOps = ref.read(hospitalOperationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Medical Specialties",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: screenWidth * 0.055,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
              size: screenWidth * 0.06,
            ),
            onPressed: () {
              ref.invalidate(specialtiesProvider);
            },
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
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.015,
              ),
              child: TextField(
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                decoration: InputDecoration(
                  hintText: 'Search specialties...',
                  hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: screenWidth * 0.06,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: screenWidth * 0.04,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ===== Grid =====
            specialtiesAsync.when(
              data: (specialties) {
                if (filteredSpecialties.isEmpty) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: screenWidth * 0.15,
                            color: Colors.grey,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            "No specialties found",
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: filteredSpecialties.length,
                        itemBuilder: (context, index) {
                          final specialty = filteredSpecialties[index];
                          final name = specialty['name']?.toString() ?? 'Unknown';
                          final picture = specialty['picture'] ?? {};
                          final imageUrl = picture['imageUrl']?.toString() ?? '';
                          
                          return GestureDetector(
                        onTap: () async {
  final originalSpecialtyName = specialty['name']?.toString() ?? '';  
  try {
    await hospitalOps.fetchHospitalsForSpecialty(originalSpecialtyName);
    if (mounted) {
      _showHospitalPopup(context, originalSpecialtyName);
    }
  } catch (e) {
    // error handling
  }
},
                            child: _buildCard(name, imageUrl, screenWidth, screenHeight),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              loading: () => Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.green,
                        strokeWidth: screenWidth * 0.008,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        "Loading specialties...",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              error: (error, stack) => Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: screenWidth * 0.15,
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
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        "Error: ${error.toString()}",
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(specialtiesProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06,
                            vertical: screenHeight * 0.0125,
                          ),
                        ),
                        child: Text(
                          "Retry",
                          style: TextStyle(fontSize: screenWidth * 0.035),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String name, String imageUrl, double screenWidth, double screenHeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
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
              width: screenWidth * 0.22,
              height: screenWidth * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: screenWidth * 0.005),
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
                        strokeWidth: screenWidth * 0.005,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.medical_services,
                      size: screenWidth * 0.18,
                      color: Colors.green,
                    );
                  },
                ),
              ),
            )
          else
            Container(
              width: screenWidth * 0.22,
              height: screenWidth * 0.22,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: screenWidth * 0.005),
              ),
              child: Icon(
                Icons.medical_services,
                size: screenWidth * 0.18,
                color: Colors.green,
              ),
            ),
          
          SizedBox(height: screenHeight * 0.01),
          
          // Specialty Name
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
            child: Text(
              name[0].toUpperCase() + name.substring(1),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
        ],
      ),
    );
  }

  void _showHospitalPopup(BuildContext context, String specialtyName) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final hospitalOps = ref.read(hospitalOperationsProvider);
    final hospitals = ref.read(hospitalsForSpecialtyProvider);
    final isLoading = ref.read(hospitalsLoadingProvider);
final hospitalsList = ref.watch(hospitalsForSpecialtyProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.015,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${specialtyName.toUpperCase()} HOSPITALS",
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: screenWidth * 0.06,
                          ),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: screenHeight * 0.001, thickness: screenWidth * 0.0025),

                  // --- Hospital Count ---
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                    child: Text(
                      "Found ${hospitalsList.length} hospitals",
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // --- Loading Indicator ---
                  if (isLoading)
                    Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: CircularProgressIndicator(
                        color: Colors.green,
                        strokeWidth: screenWidth * 0.008,
                      ),
                    )
                  else if (hospitalsList.isEmpty)
                    // --- No Hospitals Found ---
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_hospital_outlined,
                              size: screenWidth * 0.15,
                              color: Colors.grey,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              "No hospitals found",
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "for this specialty",
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
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
                        itemCount: hospitalsList.length,
                        itemBuilder: (context, index) {
                          final hospital = hospitalsList[index];
                          return _buildHospitalCard(context, hospital, specialtyName, screenWidth, screenHeight);
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

Widget _buildHospitalCard(BuildContext context, Map<String, dynamic> hospital, String specialtyName, double screenWidth, double screenHeight) {
  final hospitalOps = ref.read(hospitalOperationsProvider);
  
  // Handle image - could be a Map or null
  String imageUrl = '';
  final image = hospital['image'];
  if (image is Map) {
    imageUrl = image['imageUrl']?.toString() ?? '';
  } else if (image is String) {
    imageUrl = image;
  }
  
  // Hospital name
  final hospitalName = hospital['name']?.toString() ?? 'Hospital ${hospital['hospitalId']}';
  
  // Address - might be a Map or String
  String addressText = '';
  final address = hospital['address'];
  if (address is Map) {
    // Build a readable address from components
    final parts = <String>[];
    if (address['place'] != null) parts.add(address['place']);
    if (address['district'] != null) parts.add(address['district']);
    if (address['state'] != null) parts.add(address['state']);
    if (address['pincode'] != null) parts.add(address['pincode'].toString());
    addressText = parts.join(', ');
  } else if (address is String) {
    addressText = address;
  }
  
  // Phone
  final phone = hospital['phone']?.toString() ?? '';
  
  // Hospital ID - could be int or string
 String hospitalId = '';
// ✅ FIRST priority: numeric id field
if (hospital['id'] != null) {
  hospitalId = hospital['id'].toString();
} else if (hospital['_id'] != null) {
  hospitalId = hospital['_id'].toString();
} else if (hospital['hospitalId'] != null) {
  final rawId = hospital['hospitalId'].toString();
  if (!rawId.startsWith('#')) {
    hospitalId = rawId;
  }
}
  
  final specialtyDoctorsCount = hospitalOps.getDoctorsCountForSpecialty(hospital, specialtyName);
  final totalDoctorsCount = hospitalOps.getTotalDoctorsCount(hospital);

  return Card(
    margin: EdgeInsets.symmetric(
      horizontal: screenWidth * 0.04,
      vertical: screenHeight * 0.01,
    ),
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
    child: InkWell(
      onTap: () {
        if (hospitalId.isNotEmpty) {
          hospitalOps.navigateToDoctorsPage(context, hospitalId, specialtyName, hospitalName);
        } else {
          _showErrorSnackbar("Hospital ID not available");
        }
      },
      borderRadius: BorderRadius.circular(screenWidth * 0.03),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hospital Avatar
            _buildHospitalAvatar(imageUrl, screenWidth),
            SizedBox(width: screenWidth * 0.03),
            
            // Hospital Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital Name
                  Text(
                    hospitalName,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.0075),
                  
                  // Specialty Doctors Count
                  Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: screenWidth * 0.035,
                        color: Colors.green,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Expanded(
                        child: Text(
                          "$specialtyDoctorsCount $specialtyName doctors",
                          style: TextStyle(
                            fontSize: screenWidth * 0.0325,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.0025),
                  
                  // Total Doctors Count
                  Row(
                    children: [
                      Icon(
                        Icons.people_alt_outlined,
                        size: screenWidth * 0.035,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        "$totalDoctorsCount total doctors",
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.0075),
                  
                  // Address
                  if (addressText.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: screenWidth * 0.035,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Expanded(
                          child: Text(
                            addressText,
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
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
                    SizedBox(height: screenHeight * 0.005),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: screenWidth * 0.035,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
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
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.02),
              child: Icon(
                Icons.arrow_forward_ios,
                size: screenWidth * 0.04,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHospitalAvatar(String imageUrl, double screenWidth) {
    if (imageUrl.isNotEmpty) {
      return Container(
        width: screenWidth * 0.15,
        height: screenWidth * 0.15,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: screenWidth * 0.005),
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
                child: Center(
                  child: Icon(
                    Icons.local_hospital,
                    size: screenWidth * 0.06,
                    color: Colors.green,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return Container(
        width: screenWidth * 0.15,
        height: screenWidth * 0.15,
        decoration: BoxDecoration(
          color: Colors.green[100],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: screenWidth * 0.005),
        ),
        child: Center(
          child: Icon(
            Icons.local_hospital,
            size: screenWidth * 0.06,
            color: Colors.green,
          ),
        ),
      );
    }
  }
}