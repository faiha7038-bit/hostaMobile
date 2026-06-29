// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hosta/common/top_snackbar.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:dio/dio.dart';
// import '../../../services/api_service.dart';

// class PatientDetailsScreen extends ConsumerStatefulWidget {
//   const PatientDetailsScreen({super.key});

//   @override
//   ConsumerState<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
// }

// class _PatientDetailsScreenState extends ConsumerState<PatientDetailsScreen> {
//   List<Map<String, dynamic>> patientsList = [];
//   List<Map<String, dynamic>> filteredPatientsList = [];
//   Map<String, dynamic> currentPatient = {};
//   bool isLoading = true;
//   String? userId;
//   int? hospitalId;
//   int? selectedPatientIndex = 0;
//   String? errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _loadPatientData();
//   }

//   Future<void> _loadPatientData() async {
//     try {
//       setState(() {
//         isLoading = true;
//         errorMessage = null;
//       });

//       final prefs = await SharedPreferences.getInstance();
//       userId = prefs.getString('userId');
//       hospitalId = prefs.getInt('hospitalId');

//       print("🔍 ===== PATIENT DETAILS DEBUG =====");
//       print("🔍 UserId from SharedPreferences: $userId");
//       print("🔍 HospitalId from SharedPreferences: $hospitalId");

//       if (userId == null || userId!.isEmpty) {
//         print("❌ UserId is null or empty!");
//         setState(() {
//           isLoading = false;
//           errorMessage = "User not logged in. Please login first.";
//         });
//         return;
//       }

//       if (hospitalId == null) {
//         print("⚠️ HospitalId is null! Using default hospitalId: 1");
//         hospitalId = 1;
//         await prefs.setInt('hospitalId', hospitalId!);
//         print("✅ Default HospitalId set to: $hospitalId");
//       }

//       print("🔄 Calling API with hospitalId: $hospitalId, userId: ${int.parse(userId!)}");
//       final response = await ApiService().getPatients(
//         hospitalId: hospitalId!,
//         userId: int.parse(userId!),
//       );

//       print("📊 API Response Data: ${response.data}");

//       if (response.data == null) {
//         print("❌ Response data is null!");
//         setState(() {
//           isLoading = false;
//           errorMessage = "No response from server";
//         });
//         return;
//       }

//       if (response.data['success'] == true) {
//         print("✅ API call successful");
        
//         final data = response.data['data'];
        
//         if (data != null) {
//           List<Map<String, dynamic>> allPatients = [];
          
//           if (data is List) {
//             print("📋 Data is a List with ${data.length} items");
            
//             if (data.isNotEmpty) {
//               for (var item in data) {
//                 if (item is Map) {
//                   Map<String, dynamic> convertedMap = {};
//                   item.forEach((key, value) {
//                     convertedMap[key.toString()] = value;
//                   });
//                   allPatients.add(convertedMap);
//                 }
//               }
              
//               print("✅ Converted ${allPatients.length} patients");
              
//               // Filter patients by userId
//               filteredPatientsList = allPatients.where((patient) {
//                 final patientUserId = patient['userId'];
//                 if (patientUserId == null) return false;
//                 return patientUserId.toString() == userId;
//               }).toList();
              
//               print("👤 Total patients in hospital: ${allPatients.length}");
//               print("👤 Patients for user $userId: ${filteredPatientsList.length}");
              
//               if (filteredPatientsList.isNotEmpty) {
//                 patientsList = filteredPatientsList;
//                 currentPatient = patientsList[0];
//                 setState(() {
//                   isLoading = false;
//                   errorMessage = null;
//                 });
//               } else {
//                 setState(() {
//                   isLoading = false;
//                   errorMessage = "No patients found for user ID: $userId";
//                 });
//               }
//             } else {
//               print("⚠️ Data is an empty list");
//               setState(() {
//                 isLoading = false;
//                 errorMessage = "No patients found";
//               });
//             }
//           } else if (data is Map) {
//             print("📋 Data is a Map");
            
//             Map<String, dynamic> convertedMap = {};
//             data.forEach((key, value) {
//               convertedMap[key.toString()] = value;
//             });
            
//             final patientUserId = convertedMap['userId'];
//             if (patientUserId != null && patientUserId.toString() == userId) {
//               patientsList = [convertedMap];
//               currentPatient = convertedMap;
//             } else {
//               setState(() {
//                 isLoading = false;
//                 errorMessage = "This patient does not belong to you.";
//               });
//               return;
//             }
            
//             setState(() {
//               isLoading = false;
//               errorMessage = null;
//             });
//           } else {
//             print("⚠️ Unknown data type: ${data.runtimeType}");
//             setState(() {
//               isLoading = false;
//               errorMessage = "Unexpected data format";
//             });
//           }
//         } else {
//           print("⚠️ 'data' field is null");
//           setState(() {
//             isLoading = false;
//             errorMessage = "No patient data found";
//           });
//         }
//       } else {
//         print("❌ API returned success: false");
//         setState(() {
//           isLoading = false;
//           errorMessage = response.data['error'] ?? "Failed to load patient details";
//         });
//       }
//     } catch (e) {
//       print("❌ Error loading patient data: $e");
//       setState(() {
//         isLoading = false;
//         errorMessage = "Error: $e";
//       });
//     }
//   }

//   Future<void> _refreshPatientData() async {
//     if (userId == null || userId!.isEmpty) {
//       showTopSnackBar(context, "Please login first", isError: true);
//       return;
//     }

//     if (hospitalId == null) {
//       hospitalId = 1;
//     }

//     try {
//       setState(() {
//         isLoading = true;
//         errorMessage = null;
//       });
      
//       final response = await ApiService().getPatients(
//         hospitalId: hospitalId!,
//         userId: int.parse(userId!),
//       );

//       if (response.data != null && 
//           response.data['success'] == true && 
//           response.data['data'] != null) {
        
//         final data = response.data['data'];
//         List<Map<String, dynamic>> allPatients = [];
        
//         if (data is List && data.isNotEmpty) {
//           for (var item in data) {
//             if (item is Map) {
//               Map<String, dynamic> convertedMap = {};
//               item.forEach((key, value) {
//                 convertedMap[key.toString()] = value;
//               });
//               allPatients.add(convertedMap);
//             }
//           }
          
//           filteredPatientsList = allPatients.where((patient) {
//             final patientUserId = patient['userId'];
//             if (patientUserId == null) return false;
//             return patientUserId.toString() == userId;
//           }).toList();
          
//           if (filteredPatientsList.isNotEmpty) {
//             patientsList = filteredPatientsList;
//             currentPatient = patientsList[selectedPatientIndex ?? 0];
//             setState(() {
//               isLoading = false;
//               errorMessage = null;
//             });
//             showTopSnackBar(context, "Patient details updated successfully");
//           } else {
//             setState(() {
//               isLoading = false;
//               errorMessage = "No patients found for this user";
//             });
//           }
//         } else if (data is Map && data.isNotEmpty) {
//           Map<String, dynamic> convertedMap = {};
//           data.forEach((key, value) {
//             convertedMap[key.toString()] = value;
//           });
          
//           final patientUserId = convertedMap['userId'];
//           if (patientUserId != null && patientUserId.toString() == userId) {
//             patientsList = [convertedMap];
//             currentPatient = convertedMap;
//             setState(() {
//               isLoading = false;
//               errorMessage = null;
//             });
//             showTopSnackBar(context, "Patient details updated successfully");
//           } else {
//             setState(() {
//               isLoading = false;
//               errorMessage = "This patient does not belong to you";
//             });
//           }
//         } else {
//           setState(() {
//             isLoading = false;
//             errorMessage = "No patients found";
//           });
//         }
//       } else {
//         setState(() {
//           isLoading = false;
//           errorMessage = "Failed to refresh patient data";
//         });
//       }
//     } catch (e) {
//       print('❌ Error refreshing patient data: $e');
//       setState(() {
//         isLoading = false;
//         errorMessage = "Error: $e";
//       });
//     }
//   }

//   String _getValue(String key, {String defaultValue = ''}) {
//     try {
//       final value = currentPatient[key];
//       if (value == null) return defaultValue;
//       if (value is String && value.isEmpty) return defaultValue;
//       if (value is int && value == 0) return defaultValue;
//       return value.toString();
//     } catch (e) {
//       return defaultValue;
//     }
//   }

//   String _getLocationValue(String key, {String defaultValue = ''}) {
//     try {
//       final location = currentPatient['location'];
//       if (location == null) return defaultValue;
//       if (location is Map) {
//         final value = location[key];
//         if (value == null) return defaultValue;
//         if (value is String && value.isEmpty) return defaultValue;
//         if (value is int && value == 0) return defaultValue;
//         return value.toString();
//       }
//       return defaultValue;
//     } catch (e) {
//       return defaultValue;
//     }
//   }

//   bool _hasValue(String key) {
//     try {
//       final value = currentPatient[key];
//       if (value == null) return false;
//       if (value is String && value.isEmpty) return false;
//       if (value is int && value == 0) return false;
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }

//   bool _hasLocation() {
//     try {
//       final location = currentPatient['location'];
//       if (location == null) return false;
//       if (location is Map) {
//         final place = location['place'];
//         final pincode = location['pincode'];
//         if (place != null && place.toString().isNotEmpty) return true;
//         if (pincode != null && pincode != 0) return true;
//         return false;
//       }
//       return false;
//     } catch (e) {
//       return false;
//     }
//   }

//   void _changePatient(int index) {
//     setState(() {
//       selectedPatientIndex = index;
//       currentPatient = patientsList[index];
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final screenHeight = screenSize.height;
//     final screenWidth = screenSize.width;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Patient Details',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: screenWidth * 0.05,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: const Color(0xFF28A745),
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.white, size: screenWidth * 0.06),
//           onPressed: () => Navigator.pop(context),
//         ),
//         // actions: [
//         //   IconButton(
//         //     icon: Icon(Icons.refresh, color: Colors.white, size: screenWidth * 0.06),
//         //     onPressed: _refreshPatientData,
//         //   ),
//         // ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : errorMessage != null
//               ? _buildErrorWidget(screenWidth, screenHeight)
//               : RefreshIndicator(
//                   onRefresh: _refreshPatientData,
//                   child: SingleChildScrollView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     child: Column(
//                       children: [
//                         // Patient Dropdown Selector
//                         if (patientsList.length > 1)
//                           _buildPatientDropdown(screenWidth, screenHeight),
                        
//                         if (patientsList.length > 1)
//                           SizedBox(height: screenHeight * 0.015),
                        
//                         // Patient Header - Without Green Background and Person Icon
//                         _buildPatientHeader(screenWidth, screenHeight),
                        
//                         if (_hasValue('patientId') || _hasValue('id'))
//                           SizedBox(height: screenHeight * 0.025),
                        
//                         if (_hasValue('patientId') || _hasValue('id'))
//                           _buildPatientIdSection(screenWidth, screenHeight),
                        
//                         SizedBox(height: screenHeight * 0.025),
                        
//                         _buildPersonalInfoSection(screenWidth, screenHeight),
                        
//                         if (_hasLocation() || _hasValue('addressLine'))
//                           SizedBox(height: screenHeight * 0.025),
                        
//                         if (_hasLocation() || _hasValue('addressLine'))
//                           _buildLocationSection(screenWidth, screenHeight),
                        
//                         SizedBox(height: screenHeight * 0.025),
                        
//                         _buildStatusSection(screenWidth, screenHeight),
                        
//                         SizedBox(height: screenHeight * 0.03),
//                       ],
//                     ),
//                   ),
//                 ),
//     );
//   }

//   // Patient Dropdown Widget
//   Widget _buildPatientDropdown(double screenWidth, double screenHeight) {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: screenWidth * 0.04,
//         vertical: screenHeight * 0.01,
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(screenWidth * 0.025),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.2),
//               spreadRadius: 1,
//               blurRadius: 5,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: DropdownButtonHideUnderline(
//           child: DropdownButton<int>(
//             value: selectedPatientIndex,
//             isExpanded: true,
//             icon: Padding(
//               padding: EdgeInsets.only(right: screenWidth * 0.03),
//               child: Icon(
//                 Icons.arrow_drop_down,
//                 color: const Color(0xFF28A745),
//                 size: screenWidth * 0.07,
//               ),
//             ),
//             iconSize: screenWidth * 0.07,
//             padding: EdgeInsets.symmetric(
//               horizontal: screenWidth * 0.04,
//               vertical: screenHeight * 0.01,
//             ),
//             dropdownColor: Colors.white,
//             style: TextStyle(
//               fontSize: screenWidth * 0.04,
//               color: Colors.black87,
//               fontWeight: FontWeight.w500,
//             ),
//             items: patientsList.asMap().entries.map((entry) {
//               int index = entry.key;
//               Map<String, dynamic> patient = entry.value;
//               String patientName = patient['name'] ?? 'Patient ${index + 1}';
//               String patientId = patient['patientId'] ?? '';
              
//               return DropdownMenuItem<int>(
//                 value: index,
//                 child: Row(
//                   children: [
//                     Container(
//                       padding: EdgeInsets.all(screenWidth * 0.02),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF28A745).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(screenWidth * 0.02),
//                       ),
//                       child: Icon(
//                         Icons.person,
//                         color: const Color(0xFF28A745),
//                         size: screenWidth * 0.04,
//                       ),
//                     ),
//                     SizedBox(width: screenWidth * 0.03),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             patientName,
//                             style: TextStyle(
//                               fontSize: screenWidth * 0.04,
//                               fontWeight: FontWeight.w600,
//                               color: selectedPatientIndex == index 
//                                   ? const Color(0xFF28A745) 
//                                   : Colors.black87,
//                             ),
//                           ),
//                           if (patientId.isNotEmpty)
//                             Text(
//                               patientId,
//                               style: TextStyle(
//                                 fontSize: screenWidth * 0.03,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                     if (selectedPatientIndex == index)
//                       Icon(
//                         Icons.check_circle,
//                         color: const Color(0xFF28A745),
//                         size: screenWidth * 0.05,
//                       ),
//                   ],
//                 ),
//               );
//             }).toList(),
//             onChanged: (int? newIndex) {
//               if (newIndex != null) {
//                 _changePatient(newIndex);
//               }
//             },
//             selectedItemBuilder: (context) {
//               return patientsList.asMap().entries.map((entry) {
//                 int index = entry.key;
//                 Map<String, dynamic> patient = entry.value;
//                 String patientName = patient['name'] ?? 'Patient ${index + 1}';
                
//                 return Row(
//                   children: [
//                     Container(
//                       padding: EdgeInsets.all(screenWidth * 0.015),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF28A745).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(screenWidth * 0.02),
//                       ),
//                       child: Icon(
//                         Icons.person,
//                         color: const Color(0xFF28A745),
//                         size: screenWidth * 0.035,
//                       ),
//                     ),
//                     SizedBox(width: screenWidth * 0.025),
//                     Expanded(
//                       child: Text(
//                         patientName,
//                         style: TextStyle(
//                           fontSize: screenWidth * 0.04,
//                           fontWeight: FontWeight.w600,
//                           color: const Color(0xFF28A745),
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     Text(
//                       '${selectedPatientIndex! + 1}/${patientsList.length}',
//                       style: TextStyle(
//                         fontSize: screenWidth * 0.03,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 );
//               }).toList();
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget(double screenWidth, double screenHeight) {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(screenWidth * 0.08),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               color: Colors.red,
//               size: screenWidth * 0.15,
//             ),
//             SizedBox(height: screenHeight * 0.03),
//             Text(
//               'No Patient Details Found',
//               style: TextStyle(
//                 fontSize: screenWidth * 0.05,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.red,
//               ),
//             ),
//             SizedBox(height: screenHeight * 0.02),
//             Text(
//               errorMessage ?? 'Please book a doctor appointment first',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: screenWidth * 0.04,
//                 color: Colors.grey[700],
//               ),
//             ),
//             SizedBox(height: screenHeight * 0.02),
//             Container(
//               padding: EdgeInsets.all(screenWidth * 0.04),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(screenWidth * 0.025),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Debug Info:',
//                     style: TextStyle(
//                       fontSize: screenWidth * 0.035,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: screenHeight * 0.01),
//                   Text(
//                     'User ID: ${userId ?? "Not set"}',
//                     style: TextStyle(fontSize: screenWidth * 0.03),
//                   ),
//                   Text(
//                     'Hospital ID: ${hospitalId ?? "Not set"}',
//                     style: TextStyle(fontSize: screenWidth * 0.03),
//                   ),
//                   Text(
//                     'Patients found: ${patientsList.length}',
//                     style: TextStyle(fontSize: screenWidth * 0.03),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: screenHeight * 0.03),
//             ElevatedButton.icon(
//               onPressed: _refreshPatientData,
//               icon: Icon(Icons.refresh, size: screenWidth * 0.05),
//               label: Text(
//                 'Refresh',
//                 style: TextStyle(fontSize: screenWidth * 0.04),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF28A745),
//                 foregroundColor: Colors.white,
//                 padding: EdgeInsets.symmetric(
//                   horizontal: screenWidth * 0.08,
//                   vertical: screenHeight * 0.02,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(screenWidth * 0.025),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Updated Patient Header - Without Green Background and Person Icon
//   Widget _buildPatientHeader(double screenWidth, double screenHeight) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Patient Name
//           Text(
//             _getValue('name').isEmpty ? 'Patient Name' : _getValue('name'),
//             style: TextStyle(
//               color: Colors.black87,
//               fontSize: screenWidth * 0.06,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: screenHeight * 0.005),
          
//           // Patient ID and other info chips
//           Wrap(
//             alignment: WrapAlignment.start,
//             spacing: screenWidth * 0.025,
//             runSpacing: screenHeight * 0.005,
//             children: [
//               if (_hasValue('patientId'))
//                 _buildInfoChipLight(
//                   icon: Icons.badge_outlined,
//                   label: _getValue('patientId'),
//                   screenWidth: screenWidth,
//                 ),
//               if (_hasValue('age'))
//                 _buildInfoChipLight(
//                   icon: Icons.calendar_today_outlined,
//                   label: '${_getValue('age')} yrs',
//                   screenWidth: screenWidth,
//                 ),
//               if (_hasValue('gender'))
//                 _buildInfoChipLight(
//                   icon: Icons.wc_outlined,
//                   label: _getValue('gender'),
//                   screenWidth: screenWidth,
//                 ),
//               // Status Chip
//               _buildStatusChip(screenWidth),
//             ],
//           ),
//           SizedBox(height: screenHeight * 0.005),
          
//           // Divider
//           Divider(
//             height: screenHeight * 0.02,
//             thickness: 1,
//             color: Colors.grey[200],
//           ),
//         ],
//       ),
//     );
//   }

//   // Light Info Chip (Without Green Background)
//   Widget _buildInfoChipLight({
//     required IconData icon,
//     required String label,
//     required double screenWidth,
//   }) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: screenWidth * 0.03,
//         vertical: screenWidth * 0.015,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(screenWidth * 0.05),
//         border: Border.all(
//           color: Colors.grey[300]!,
//           width: 0.5,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             color: Colors.grey[600],
//             size: screenWidth * 0.035,
//           ),
//           SizedBox(width: screenWidth * 0.01),
//           Text(
//             label,
//             style: TextStyle(
//               color: Colors.grey[700],
//               fontSize: screenWidth * 0.03,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Status Chip
//   Widget _buildStatusChip(double screenWidth) {
//     final isActive = currentPatient['isActive'] == true;
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: screenWidth * 0.03,
//         vertical: screenWidth * 0.015,
//       ),
//       decoration: BoxDecoration(
//         color: isActive ? Colors.green[50] : Colors.red[50],
//         borderRadius: BorderRadius.circular(screenWidth * 0.05),
//         border: Border.all(
//           color: isActive ? Colors.green[300]! : Colors.red[300]!,
//           width: 0.5,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isActive ? Icons.verified : Icons.block,
//             color: isActive ? Colors.green[700] : Colors.red[700],
//             size: screenWidth * 0.035,
//           ),
//           SizedBox(width: screenWidth * 0.01),
//           Text(
//             isActive ? 'Active' : 'Inactive',
//             style: TextStyle(
//               color: isActive ? Colors.green[700] : Colors.red[700],
//               fontSize: screenWidth * 0.03,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPatientIdSection(double screenWidth, double screenHeight) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
//       child: Card(
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(screenWidth * 0.025),
//           side: BorderSide(color: Colors.grey[200]!, width: 1),
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(screenWidth * 0.04),
//           child: Row(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(screenWidth * 0.02),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF28A745).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(screenWidth * 0.025),
//                 ),
//                 child: Icon(
//                   Icons.qr_code,
//                   color: const Color(0xFF28A745),
//                   size: screenWidth * 0.06,
//                 ),
//               ),
//               SizedBox(width: screenWidth * 0.03),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Patient ID',
//                       style: TextStyle(
//                         fontSize: screenWidth * 0.032,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     Text(
//                       _getValue('patientId').isEmpty ? 'Not Available' : _getValue('patientId'),
//                       style: TextStyle(
//                         fontSize: screenWidth * 0.04,
//                         fontWeight: FontWeight.bold,
//                         color: const Color(0xFF28A745),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               if (_hasValue('id'))
//                 Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: screenWidth * 0.04,
//                     vertical: screenHeight * 0.005,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF28A745).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(screenWidth * 0.025),
//                   ),
//                   child: Text(
//                     'ID: ${_getValue('id')}',
//                     style: TextStyle(
//                       fontSize: screenWidth * 0.032,
//                       color: const Color(0xFF28A745),
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title, IconData icon, double screenWidth) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: screenWidth * 0.03,
//         vertical: screenWidth * 0.02,
//       ),
//       decoration: BoxDecoration(
//         color: const Color(0xFF28A745).withOpacity(0.1),
//         borderRadius: BorderRadius.circular(screenWidth * 0.025),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(screenWidth * 0.02),
//             decoration: BoxDecoration(
//               color: const Color(0xFF28A745),
//               borderRadius: BorderRadius.circular(screenWidth * 0.025),
//             ),
//             child: Icon(
//               icon,
//               color: Colors.white,
//               size: screenWidth * 0.045,
//             ),
//           ),
//           SizedBox(width: screenWidth * 0.025),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: screenWidth * 0.04,
//               fontWeight: FontWeight.bold,
//               color: const Color(0xFF28A745),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPersonalInfoSection(double screenWidth, double screenHeight) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSectionHeader('Personal Information', Icons.person_outline, screenWidth),
//           SizedBox(height: screenHeight * 0.012),
//           Card(
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(screenWidth * 0.025),
//               side: BorderSide(color: Colors.grey[200]!, width: 1),
//             ),
//             child: Padding(
//               padding: EdgeInsets.all(screenWidth * 0.04),
//               child: Column(
//                 children: [
//                   _buildInfoRow(
//                     icon: Icons.person_outline,
//                     label: 'Full Name',
//                     value: _getValue('name').isEmpty ? 'Not Available' : _getValue('name'),
//                     screenWidth: screenWidth,
//                   ),
//                   if (_hasValue('mobileNumber')) ...[
//                     _buildDivider(screenWidth),
//                     _buildInfoRow(
//                       icon: Icons.phone_outlined,
//                       label: 'Mobile Number',
//                       value: _getValue('mobileNumber'),
//                       screenWidth: screenWidth,
//                     ),
//                   ],
//                   if (_hasValue('email')) ...[
//                     _buildDivider(screenWidth),
//                     _buildInfoRow(
//                       icon: Icons.email_outlined,
//                       label: 'Email',
//                       value: _getValue('email'),
//                       screenWidth: screenWidth,
//                     ),
//                   ],
//                   if (_hasValue('dob')) ...[
//                     _buildDivider(screenWidth),
//                     _buildInfoRow(
//                       icon: Icons.calendar_today,
//                       label: 'Date of Birth',
//                       value: _getValue('dob'),
//                       screenWidth: screenWidth,
//                     ),
//                   ],
                  
//                   if (_hasValue('gender')) ...[
//                     _buildDivider(screenWidth),
//                     _buildInfoRow(
//                       icon: Icons.wc,
//                       label: 'Gender',
//                       value: _getValue('gender'),
//                       screenWidth: screenWidth,
//                     ),
//                   ],
//                   if (_hasValue('bloodGroup')) ...[
//                     _buildDivider(screenWidth),
//                     _buildInfoRow(
//                       icon: Icons.bloodtype,
//                       label: 'Blood Group',
//                       value: _getValue('bloodGroup'),
//                       screenWidth: screenWidth,
//                     ),
//                   ],
//                   if (_hasValue('maritalStatus')) ...[
//                     _buildDivider(screenWidth),
//                     _buildInfoRow(
//                       icon: Icons.family_restroom,
//                       label: 'Marital Status',
//                       value: _getValue('maritalStatus'),
//                       screenWidth: screenWidth,
//                     ),
//                   ],
//                   if (_hasValue('patientType')) ...[
//                     _buildDivider(screenWidth),
//                     _buildInfoRow(
//                       icon: Icons.medical_information,
//                       label: 'Patient Type',
//                       value: _getValue('patientType'),
//                       screenWidth: screenWidth,
//                     ),
//                   ],
//                   if (_hasValue('guardianName')) ...[
//                     _buildDivider(screenWidth),
//                     _buildInfoRow(
//                       icon: Icons.person,
//                       label: 'Guardian Name',
//                       value: _getValue('guardianName'),
//                       screenWidth: screenWidth,
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLocationSection(double screenWidth, double screenHeight) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSectionHeader('Location Information', Icons.location_on, screenWidth),
//           SizedBox(height: screenHeight * 0.012),
//           Card(
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(screenWidth * 0.025),
//               side: BorderSide(color: Colors.grey[200]!, width: 1),
//             ),
//             child: Padding(
//               padding: EdgeInsets.all(screenWidth * 0.04),
//               child: Column(
//                 children: [
//                   if (_hasValue('addressLine'))
//                     _buildInfoRow(
//                       icon: Icons.location_on_outlined,
//                       label: 'Address Line',
//                       value: _getValue('addressLine'),
//                       screenWidth: screenWidth,
//                     ),
//                   if (_hasValue('addressLine') && _hasLocation())
//                     _buildDivider(screenWidth),
//                   if (_hasLocation()) ...[
//                     if (_getLocationValue('place').isNotEmpty) ...[
//                       _buildInfoRow(
//                         icon: Icons.place,
//                         label: 'Place',
//                         value: _getLocationValue('place'),
//                         screenWidth: screenWidth,
//                       ),
//                       if (_getLocationValue('pincode').isNotEmpty)
//                         _buildDivider(screenWidth),
//                     ],
//                     if (_getLocationValue('pincode').isNotEmpty)
//                       _buildInfoRow(
//                         icon: Icons.pin_drop,
//                         label: 'Pincode',
//                         value: _getLocationValue('pincode'),
//                         screenWidth: screenWidth,
//                       ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusSection(double screenWidth, double screenHeight) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSectionHeader('Status Information', Icons.info_outline, screenWidth),
//           SizedBox(height: screenHeight * 0.012),
//           Card(
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(screenWidth * 0.025),
//               side: BorderSide(color: Colors.grey[200]!, width: 1),
//             ),
//             child: Padding(
//               padding: EdgeInsets.all(screenWidth * 0.04),
//               child: Column(
//                 children: [
//                   _buildInfoRow(
//                     icon: Icons.check_circle_outline,
//                     label: 'Status',
//                     value: currentPatient['isActive'] == true ? 'Active' : 'Inactive',
//                     screenWidth: screenWidth,
//                   ),
//                   _buildDivider(screenWidth),
//                   _buildInfoRow(
//                     icon: Icons.calendar_today,
//                     label: 'Created At',
//                     value: _getValue('createdAt').isEmpty ? 'Not Available' : _getValue('createdAt'),
//                     screenWidth: screenWidth,
//                   ),
//                   if (_hasValue('updatedAt')) ...[
//                     _buildDivider(screenWidth),
//                     _buildInfoRow(
//                       icon: Icons.update,
//                       label: 'Last Updated',
//                       value: _getValue('updatedAt'),
//                       screenWidth: screenWidth,
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow({
//     required IconData icon,
//     required String label,
//     required String value,
//     required double screenWidth,
//   }) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(screenWidth * 0.015),
//             decoration: BoxDecoration(
//               color: const Color(0xFF28A745).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(screenWidth * 0.02),
//             ),
//             child: Icon(
//               icon,
//               color: const Color(0xFF28A745),
//               size: screenWidth * 0.04,
//             ),
//           ),
//           SizedBox(width: screenWidth * 0.03),
//           SizedBox(
//             width: screenWidth * 0.28,
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.w500,
//                 fontSize: screenWidth * 0.035,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontSize: screenWidth * 0.035,
//                 color: Colors.black87,
//                 fontWeight: FontWeight.w400,
//               ),
//               textAlign: TextAlign.end,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDivider(double screenWidth) {
//     return Divider(
//       height: 0,
//       thickness: 0.5,
//       color: Colors.grey[300],
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../services/api_service.dart';

class PatientDetailsScreen extends ConsumerStatefulWidget {
  const PatientDetailsScreen({super.key});

  @override
  ConsumerState<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends ConsumerState<PatientDetailsScreen> {
  List<Map<String, dynamic>> patientsList = [];
  List<Map<String, dynamic>> filteredPatientsList = [];
  Map<String, dynamic> currentPatient = {};
  bool isLoading = true;
  String? userId;
  int? hospitalId;
  int? selectedPatientIndex = 0;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  // ==================== DATE FORMATTING METHODS ====================
  
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Not Available';
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return "${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}";
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) return 'Not Available';
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      return "${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}";
    } catch (e) {
      return dateTimeString;
    }
  }

  String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  // ==================== END DATE FORMATTING METHODS ====================

  Future<void> _loadPatientData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      hospitalId = prefs.getInt('hospitalId');

      print("🔍 ===== PATIENT DETAILS DEBUG =====");
      print("🔍 UserId from SharedPreferences: $userId");
      print("🔍 HospitalId from SharedPreferences: $hospitalId");

      if (userId == null || userId!.isEmpty) {
        print("❌ UserId is null or empty!");
        setState(() {
          isLoading = false;
          errorMessage = "User not logged in. Please login first.";
        });
        return;
      }

      if (hospitalId == null) {
        print("⚠️ HospitalId is null! Using default hospitalId: 1");
        hospitalId = 1;
        await prefs.setInt('hospitalId', hospitalId!);
        print("✅ Default HospitalId set to: $hospitalId");
      }

      print("🔄 Calling API with hospitalId: $hospitalId, userId: ${int.parse(userId!)}");
      final response = await ApiService().getPatients(
        hospitalId: hospitalId!,
        userId: int.parse(userId!),
      );

      print("📊 API Response Data: ${response.data}");

      if (response.data == null) {
        print("❌ Response data is null!");
        setState(() {
          isLoading = false;
          errorMessage = "No response from server";
        });
        return;
      }

      if (response.data['success'] == true) {
        print("✅ API call successful");
        
        final data = response.data['data'];
        
        if (data != null) {
          List<Map<String, dynamic>> allPatients = [];
          
          if (data is List) {
            print("📋 Data is a List with ${data.length} items");
            
            if (data.isNotEmpty) {
              for (var item in data) {
                if (item is Map) {
                  Map<String, dynamic> convertedMap = {};
                  item.forEach((key, value) {
                    convertedMap[key.toString()] = value;
                  });
                  allPatients.add(convertedMap);
                }
              }
              
              print("✅ Converted ${allPatients.length} patients");
              
              // Filter patients by userId
              filteredPatientsList = allPatients.where((patient) {
                final patientUserId = patient['userId'];
                if (patientUserId == null) return false;
                return patientUserId.toString() == userId;
              }).toList();
              
              print("👤 Total patients in hospital: ${allPatients.length}");
              print("👤 Patients for user $userId: ${filteredPatientsList.length}");
              
              if (filteredPatientsList.isNotEmpty) {
                patientsList = filteredPatientsList;
                currentPatient = patientsList[0];
                setState(() {
                  isLoading = false;
                  errorMessage = null;
                });
              } else {
                setState(() {
                  isLoading = false;
                  errorMessage = "No patients found for user ID: $userId";
                });
              }
            } else {
              print("⚠️ Data is an empty list");
              setState(() {
                isLoading = false;
                errorMessage = "No patients found";
              });
            }
          } else if (data is Map) {
            print("📋 Data is a Map");
            
            Map<String, dynamic> convertedMap = {};
            data.forEach((key, value) {
              convertedMap[key.toString()] = value;
            });
            
            final patientUserId = convertedMap['userId'];
            if (patientUserId != null && patientUserId.toString() == userId) {
              patientsList = [convertedMap];
              currentPatient = convertedMap;
            } else {
              setState(() {
                isLoading = false;
                errorMessage = "This patient does not belong to you.";
              });
              return;
            }
            
            setState(() {
              isLoading = false;
              errorMessage = null;
            });
          } else {
            print("⚠️ Unknown data type: ${data.runtimeType}");
            setState(() {
              isLoading = false;
              errorMessage = "Unexpected data format";
            });
          }
        } else {
          print("⚠️ 'data' field is null");
          setState(() {
            isLoading = false;
            errorMessage = "No patient data found";
          });
        }
      } else {
        print("❌ API returned success: false");
        setState(() {
          isLoading = false;
          errorMessage = response.data['error'] ?? "Failed to load patient details";
        });
      }
    } catch (e) {
      print("❌ Error loading patient data: $e");
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  Future<void> _refreshPatientData() async {
    if (userId == null || userId!.isEmpty) {
      showTopSnackBar(context, "Please login first", isError: true);
      return;
    }

    if (hospitalId == null) {
      hospitalId = 1;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      final response = await ApiService().getPatients(
        hospitalId: hospitalId!,
        userId: int.parse(userId!),
      );

      if (response.data != null && 
          response.data['success'] == true && 
          response.data['data'] != null) {
        
        final data = response.data['data'];
        List<Map<String, dynamic>> allPatients = [];
        
        if (data is List && data.isNotEmpty) {
          for (var item in data) {
            if (item is Map) {
              Map<String, dynamic> convertedMap = {};
              item.forEach((key, value) {
                convertedMap[key.toString()] = value;
              });
              allPatients.add(convertedMap);
            }
          }
          
          filteredPatientsList = allPatients.where((patient) {
            final patientUserId = patient['userId'];
            if (patientUserId == null) return false;
            return patientUserId.toString() == userId;
          }).toList();
          
          if (filteredPatientsList.isNotEmpty) {
            patientsList = filteredPatientsList;
            currentPatient = patientsList[selectedPatientIndex ?? 0];
            setState(() {
              isLoading = false;
              errorMessage = null;
            });
            showTopSnackBar(context, "Patient details updated successfully");
          } else {
            setState(() {
              isLoading = false;
              errorMessage = "No patients found for this user";
            });
          }
        } else if (data is Map && data.isNotEmpty) {
          Map<String, dynamic> convertedMap = {};
          data.forEach((key, value) {
            convertedMap[key.toString()] = value;
          });
          
          final patientUserId = convertedMap['userId'];
          if (patientUserId != null && patientUserId.toString() == userId) {
            patientsList = [convertedMap];
            currentPatient = convertedMap;
            setState(() {
              isLoading = false;
              errorMessage = null;
            });
            showTopSnackBar(context, "Patient details updated successfully");
          } else {
            setState(() {
              isLoading = false;
              errorMessage = "This patient does not belong to you";
            });
          }
        } else {
          setState(() {
            isLoading = false;
            errorMessage = "No patients found";
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to refresh patient data";
        });
      }
    } catch (e) {
      print('❌ Error refreshing patient data: $e');
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  String _getValue(String key, {String defaultValue = ''}) {
    try {
      final value = currentPatient[key];
      if (value == null) return defaultValue;
      if (value is String && value.isEmpty) return defaultValue;
      if (value is int && value == 0) return defaultValue;
      return value.toString();
    } catch (e) {
      return defaultValue;
    }
  }

  String _getLocationValue(String key, {String defaultValue = ''}) {
    try {
      final location = currentPatient['location'];
      if (location == null) return defaultValue;
      if (location is Map) {
        final value = location[key];
        if (value == null) return defaultValue;
        if (value is String && value.isEmpty) return defaultValue;
        if (value is int && value == 0) return defaultValue;
        return value.toString();
      }
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  bool _hasValue(String key) {
    try {
      final value = currentPatient[key];
      if (value == null) return false;
      if (value is String && value.isEmpty) return false;
      if (value is int && value == 0) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _hasLocation() {
    try {
      final location = currentPatient['location'];
      if (location == null) return false;
      if (location is Map) {
        final place = location['place'];
        final pincode = location['pincode'];
        if (place != null && place.toString().isNotEmpty) return true;
        if (pincode != null && pincode != 0) return true;
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _changePatient(int index) {
    setState(() {
      selectedPatientIndex = index;
      currentPatient = patientsList[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Patient Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF28A745),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: screenWidth * 0.06),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorWidget(screenWidth, screenHeight)
              : RefreshIndicator(
                  onRefresh: _refreshPatientData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Patient Dropdown Selector
                        if (patientsList.length > 1)
                          _buildPatientDropdown(screenWidth, screenHeight),
                        
                        if (patientsList.length > 1)
                          SizedBox(height: screenHeight * 0.015),
                        
                        // Patient Header - Without Green Background and Person Icon
                        _buildPatientHeader(screenWidth, screenHeight),
                        
                        if (_hasValue('patientId') || _hasValue('id'))
                          SizedBox(height: screenHeight * 0.025),
                        
                        if (_hasValue('patientId') || _hasValue('id'))
                          _buildPatientIdSection(screenWidth, screenHeight),
                        
                        SizedBox(height: screenHeight * 0.025),
                        
                        _buildPersonalInfoSection(screenWidth, screenHeight),
                        
                        if (_hasLocation() || _hasValue('addressLine'))
                          SizedBox(height: screenHeight * 0.025),
                        
                        if (_hasLocation() || _hasValue('addressLine'))
                          _buildLocationSection(screenWidth, screenHeight),
                        
                        SizedBox(height: screenHeight * 0.025),
                        
                        _buildStatusSection(screenWidth, screenHeight),
                        
                        SizedBox(height: screenHeight * 0.03),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Patient Dropdown Widget
  Widget _buildPatientDropdown(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedPatientIndex,
            isExpanded: true,
            icon: Padding(
              padding: EdgeInsets.only(right: screenWidth * 0.03),
              child: Icon(
                Icons.arrow_drop_down,
                color: const Color(0xFF28A745),
                size: screenWidth * 0.07,
              ),
            ),
            iconSize: screenWidth * 0.07,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.01,
            ),
            dropdownColor: Colors.white,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            items: patientsList.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> patient = entry.value;
              String patientName = patient['name'] ?? 'Patient ${index + 1}';
              String patientId = patient['patientId'] ?? '';
              
              return DropdownMenuItem<int>(
                value: index,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      decoration: BoxDecoration(
                        color: const Color(0xFF28A745).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Icon(
                        Icons.person,
                        color: const Color(0xFF28A745),
                        size: screenWidth * 0.04,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            patientName,
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                              color: selectedPatientIndex == index 
                                  ? const Color(0xFF28A745) 
                                  : Colors.black87,
                            ),
                          ),
                          if (patientId.isNotEmpty)
                            Text(
                              patientId,
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (selectedPatientIndex == index)
                      Icon(
                        Icons.check_circle,
                        color: const Color(0xFF28A745),
                        size: screenWidth * 0.05,
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (int? newIndex) {
              if (newIndex != null) {
                _changePatient(newIndex);
              }
            },
            selectedItemBuilder: (context) {
              return patientsList.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> patient = entry.value;
                String patientName = patient['name'] ?? 'Patient ${index + 1}';
                
                return Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.015),
                      decoration: BoxDecoration(
                        color: const Color(0xFF28A745).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Icon(
                        Icons.person,
                        color: const Color(0xFF28A745),
                        size: screenWidth * 0.035,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.025),
                    Expanded(
                      child: Text(
                        patientName,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF28A745),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${selectedPatientIndex! + 1}/${patientsList.length}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(double screenWidth, double screenHeight) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: screenWidth * 0.15,
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              'No Patient Details Found',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              errorMessage ?? 'Please book a doctor appointment first',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Info:',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'User ID: ${userId ?? "Not set"}',
                    style: TextStyle(fontSize: screenWidth * 0.03),
                  ),
                  Text(
                    'Hospital ID: ${hospitalId ?? "Not set"}',
                    style: TextStyle(fontSize: screenWidth * 0.03),
                  ),
                  Text(
                    'Patients found: ${patientsList.length}',
                    style: TextStyle(fontSize: screenWidth * 0.03),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            ElevatedButton.icon(
              onPressed: _refreshPatientData,
              icon: Icon(Icons.refresh, size: screenWidth * 0.05),
              label: Text(
                'Refresh',
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF28A745),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenHeight * 0.02,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated Patient Header - Without Green Background and Person Icon
  Widget _buildPatientHeader(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Name
          Text(
            _getValue('name').isEmpty ? 'Patient Name' : _getValue('name'),
            style: TextStyle(
              color: Colors.black87,
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          
          // Patient ID and other info chips
          Wrap(
            alignment: WrapAlignment.start,
            spacing: screenWidth * 0.025,
            runSpacing: screenHeight * 0.005,
            children: [
              if (_hasValue('patientId'))
                _buildInfoChipLight(
                  icon: Icons.badge_outlined,
                  label: _getValue('patientId'),
                  screenWidth: screenWidth,
                ),
              if (_hasValue('age'))
                _buildInfoChipLight(
                  icon: Icons.calendar_today_outlined,
                  label: '${_getValue('age')} yrs',
                  screenWidth: screenWidth,
                ),
              if (_hasValue('gender'))
                _buildInfoChipLight(
                  icon: Icons.wc_outlined,
                  label: _getValue('gender'),
                  screenWidth: screenWidth,
                ),
              // Status Chip
              _buildStatusChip(screenWidth),
            ],
          ),
          SizedBox(height: screenHeight * 0.005),
          
          // Divider
          Divider(
            height: screenHeight * 0.02,
            thickness: 1,
            color: Colors.grey[200],
          ),
        ],
      ),
    );
  }

  // Light Info Chip (Without Green Background)
  Widget _buildInfoChipLight({
    required IconData icon,
    required String label,
    required double screenWidth,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenWidth * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: screenWidth * 0.035,
          ),
          SizedBox(width: screenWidth * 0.01),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Status Chip
  Widget _buildStatusChip(double screenWidth) {
    final isActive = currentPatient['isActive'] == true;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenWidth * 0.015,
      ),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        border: Border.all(
          color: isActive ? Colors.green[300]! : Colors.red[300]!,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.verified : Icons.block,
            color: isActive ? Colors.green[700] : Colors.red[700],
            size: screenWidth * 0.035,
          ),
          SizedBox(width: screenWidth * 0.01),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive ? Colors.green[700] : Colors.red[700],
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientIdSection(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: const Color(0xFF28A745).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
                child: Icon(
                  Icons.qr_code,
                  color: const Color(0xFF28A745),
                  size: screenWidth * 0.06,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient ID',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _getValue('patientId').isEmpty ? 'Not Available' : _getValue('patientId'),
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF28A745),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasValue('id'))
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF28A745).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  child: Text(
                    'ID: ${_getValue('id')}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: const Color(0xFF28A745),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF28A745).withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: const Color(0xFF28A745),
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: screenWidth * 0.045,
            ),
          ),
          SizedBox(width: screenWidth * 0.025),
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF28A745),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal Information', Icons.person_outline, screenWidth),
          SizedBox(height: screenHeight * 0.012),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
              side: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: _getValue('name').isEmpty ? 'Not Available' : _getValue('name'),
                    screenWidth: screenWidth,
                  ),
                  if (_hasValue('mobileNumber')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Mobile Number',
                      value: _getValue('mobileNumber'),
                      screenWidth: screenWidth,
                    ),
                  ],
                  if (_hasValue('email')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _getValue('email'),
                      screenWidth: screenWidth,
                    ),
                  ],
                  // ========== FIXED: Date of Birth formatting ==========
                  if (_hasValue('dob')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date of Birth',
                      value: _formatDate(_getValue('dob')),
                      screenWidth: screenWidth,
                    ),
                  ],
                  // ========== END FIX ==========
                  
                  if (_hasValue('gender')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.wc,
                      label: 'Gender',
                      value: _getValue('gender'),
                      screenWidth: screenWidth,
                    ),
                  ],
                  if (_hasValue('bloodGroup')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.bloodtype,
                      label: 'Blood Group',
                      value: _getValue('bloodGroup'),
                      screenWidth: screenWidth,
                    ),
                  ],
                  if (_hasValue('maritalStatus')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.family_restroom,
                      label: 'Marital Status',
                      value: _getValue('maritalStatus'),
                      screenWidth: screenWidth,
                    ),
                  ],
                  if (_hasValue('patientType')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.medical_information,
                      label: 'Patient Type',
                      value: _getValue('patientType'),
                      screenWidth: screenWidth,
                    ),
                  ],
                  if (_hasValue('guardianName')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'Guardian Name',
                      value: _getValue('guardianName'),
                      screenWidth: screenWidth,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Location Information', Icons.location_on, screenWidth),
          SizedBox(height: screenHeight * 0.012),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
              side: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  if (_hasValue('addressLine'))
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address Line',
                      value: _getValue('addressLine'),
                      screenWidth: screenWidth,
                    ),
                  if (_hasValue('addressLine') && _hasLocation())
                    _buildDivider(screenWidth),
                  if (_hasLocation()) ...[
                    if (_getLocationValue('place').isNotEmpty) ...[
                      _buildInfoRow(
                        icon: Icons.place,
                        label: 'Place',
                        value: _getLocationValue('place'),
                        screenWidth: screenWidth,
                      ),
                      if (_getLocationValue('pincode').isNotEmpty)
                        _buildDivider(screenWidth),
                    ],
                    if (_getLocationValue('pincode').isNotEmpty)
                      _buildInfoRow(
                        icon: Icons.pin_drop,
                        label: 'Pincode',
                        value: _getLocationValue('pincode'),
                        screenWidth: screenWidth,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Status Information', Icons.info_outline, screenWidth),
          SizedBox(height: screenHeight * 0.012),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
              side: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.check_circle_outline,
                    label: 'Status',
                    value: currentPatient['isActive'] == true ? 'Active' : 'Inactive',
                    screenWidth: screenWidth,
                  ),
                  _buildDivider(screenWidth),
                  // ========== FIXED: Created At formatting ==========
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Created At',
                    value: _getValue('createdAt').isEmpty 
                        ? 'Not Available' 
                        : _formatDateTime(_getValue('createdAt')),
                    screenWidth: screenWidth,
                  ),
                  // ========== END FIX ==========
                  // ========== FIXED: Updated At formatting ==========
                  if (_hasValue('updatedAt')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.update,
                      label: 'Last Updated',
                      value: _formatDateTime(_getValue('updatedAt')),
                      screenWidth: screenWidth,
                    ),
                  ],
                  // ========== END FIX ==========
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required double screenWidth,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.015),
            decoration: BoxDecoration(
              color: const Color(0xFF28A745).withOpacity(0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF28A745),
              size: screenWidth * 0.04,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          SizedBox(
            width: screenWidth * 0.28,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: screenWidth * 0.035,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(double screenWidth) {
    return Divider(
      height: 0,
      thickness: 0.5,
      color: Colors.grey[300],
    );
  }
}