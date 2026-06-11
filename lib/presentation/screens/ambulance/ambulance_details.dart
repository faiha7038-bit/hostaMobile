import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/presentation/screens/ambulance/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hosta/providers/amb_detail-provider.dart';

class AmbulanceDetailsPage extends ConsumerStatefulWidget {
  const AmbulanceDetailsPage({super.key});

  @override
  ConsumerState<AmbulanceDetailsPage> createState() => _AmbulanceDetailsPageState();
}

class _AmbulanceDetailsPageState extends ConsumerState<AmbulanceDetailsPage> {
  @override
  void initState() {
    super.initState();
    _loadAmbulances();
  }

  // Future<void> _loadAmbulances() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final userId = prefs.getString('userId');
  //   if (userId == null) return;
  //   await ref.read(ambulanceListProvider.notifier).fetchAmbulances(userId: userId);
  // }
Future<void> _loadAmbulances() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  if (userId == null) return;
  
  await ref.read(ambulanceListProvider.notifier).fetchAmbulances(userId: userId);
  
  final state = ref.read(ambulanceListProvider);
  
  // ✅ If no ambulances left, clear the registration flag
  if (state.ambulances.isEmpty) {
    await prefs.remove('ambulanceRegistered');
    await prefs.remove('ambulanceId');
    log("🔄 Cleared ambulance flag – no ambulances remaining");
  } else {
    // Ensure flag is true when ambulances exist (already set on registration)
  }
}
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final state = ref.watch(ambulanceListProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Ambulance Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
          ),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: screenWidth * 0.055),
        ),
        // Removed actions – the add icon is now a FloatingActionButton
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.ambulances.isEmpty
              ? _noAmbulanceUI(context, screenWidth, screenHeight)
              : ListView.builder(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  itemCount: state.ambulances.length,
                  itemBuilder: (context, index) {
                    final ambulance = state.ambulances[index];
                    return _ambulanceCard(ambulance, screenWidth, screenHeight);
                  },
                ),
      // FloatingActionButton – only shown when there is at least one ambulance
      floatingActionButton: state.ambulances.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AmbulanceRegister()),
                );
                 if (result != null && result['refresh'] == true) {
            _loadAmbulances();
          }
               // if (result == true) _loadAmbulances();
              },
              backgroundColor: Colors.green,
              child: Icon(
                Icons.add_circle_outline_outlined,
                color: Colors.white,
                size: screenWidth * 0.08,
              ),
            )
          : null,
    );
  }

  Widget _noAmbulanceUI(BuildContext context, double screenWidth, double screenHeight) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(screenWidth * 0.04),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_hospital, size: screenWidth * 0.15, color: Colors.green),
              SizedBox(height: screenHeight * 0.0125),
              Text("No Ambulance Registered",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
              SizedBox(height: screenHeight * 0.0125),
              ElevatedButton(
                onPressed: () async {
                 final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AmbulanceRegister()),
                  );
                    if (result != null && result['refresh'] == true) {
      _loadAmbulances();
    }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.015),
                ),
                child: Text("Register Ambulance",
                    style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ambulanceCard(Map<String, dynamic> ambulance, double screenWidth, double screenHeight) {
    final serviceName = ambulance['serviceName'] ?? 'Not specified';
    final vehicleType = ambulance['vehicleType'] ?? 'Not specified';
    final phone = ambulance['phone'] ?? 'Not available';

    final ambulanceId = (ambulance['id'] ?? ambulance['_id']).toString();

    final address = ambulance['address'] as Map<String, dynamic>?;
    final place = address?['place'] ?? '';
    final district = address?['district'] ?? '';
    final stateName = address?['state'] ?? '';
    final location = [place, district, stateName].where((s) => s.isNotEmpty).join(', ');
    final fullLocation = location.isEmpty ? 'Not provided' : location;

    return Card(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    serviceName,
                    style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: screenWidth * 0.06),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AmbulanceRegister(editData: ambulance),
                        ),
                      );
                       if (result != null && result['refresh'] == true) {
    _loadAmbulances();
  }
                      //if (result == true) _loadAmbulances();
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Delete Ambulance"),
                          content: const Text("Are you sure you want to delete this ambulance record?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final success = await ref.read(ambulanceListProvider.notifier)
                            .deleteAmbulance(ambulanceId);
                        if (mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Ambulance deleted successfully"),
                                backgroundColor: Colors.green),
                          );
                          _loadAmbulances();
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.black, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.008),
            Text("Service: $serviceName", style: TextStyle(fontSize: screenWidth * 0.04)),
            Text("Vehicle Type: $vehicleType", style: TextStyle(fontSize: screenWidth * 0.04)),
            Text("Phone: $phone", style: TextStyle(fontSize: screenWidth * 0.04)),
            Text("Location: $fullLocation", style: TextStyle(fontSize: screenWidth * 0.04)),
          ],
        ),
      ),
    );
  }
}