import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/presentation/screens/ambulance/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hosta/providers/amb_detail-provider.dart';

class AmbulanceDetailsPage extends ConsumerStatefulWidget {
  const AmbulanceDetailsPage({super.key});

  @override
  ConsumerState<AmbulanceDetailsPage> createState() =>
      _AmbulanceDetailsPageState();
}

class _AmbulanceDetailsPageState extends ConsumerState<AmbulanceDetailsPage> {
  @override
  void initState() {
    super.initState();
    _loadAmbulances();
  }

  Future<void> _loadAmbulances() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    await ref
        .read(ambulanceListProvider.notifier)
        .fetchAmbulances(userId: userId);

    final state = ref.read(ambulanceListProvider);
    if (state.ambulances.isEmpty) {
      await prefs.remove('ambulanceRegistered');
      await prefs.remove('ambulanceId');
    } else {
      final firstAmbulance = state.ambulances.first;

      final ambulanceId =
          (firstAmbulance['id'] ?? firstAmbulance['_id']).toString();

      await prefs.setBool('ambulanceRegistered', true);
      await prefs.setString('ambulanceId', ambulanceId);
    }

    if (state.ambulances.isEmpty) {
      await prefs.remove('ambulanceRegistered');
      await prefs.remove('ambulanceId');
    } else {}
  }

  // Helper to clamp responsive values
  double _clamp(double value, double min, double max) =>
      value.clamp(min, max) as double;

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
            fontSize: _clamp(screenWidth * 0.05, 16, 24),
          ),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: _clamp(screenWidth * 0.055, 20, 32)),
        ),
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
                    return _ambulanceCard(
                        ambulance, screenWidth, screenHeight, context);
                  },
                ),
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
              },
              backgroundColor: Colors.green,
              child: Icon(
                Icons.add_circle_outline_outlined,
                color: Colors.white,
                size: _clamp(screenWidth * 0.08, 28, 48),
              ),
            )
          : null,
    );
  }

  Widget _noAmbulanceUI(
      BuildContext context, double screenWidth, double screenHeight) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(screenWidth * 0.04),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_hospital,
                  size: _clamp(screenWidth * 0.15, 60, 100),
                  color: Colors.green),
              SizedBox(height: screenHeight * 0.0125),
              Text("No Ambulance Registered",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: _clamp(screenWidth * 0.045, 16, 24))),
              SizedBox(height: screenHeight * 0.0125),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AmbulanceRegister()),
                  );
                  if (result != null && result['refresh'] == true) {
                    _loadAmbulances();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.015),
                ),
                child: Text("Register Ambulance",
                    style: TextStyle(
                        fontSize: _clamp(screenWidth * 0.035, 14, 20),
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ambulanceCard(Map<String, dynamic> ambulance, double screenWidth,
      double screenHeight, BuildContext context) {
    final serviceName = ambulance['serviceName'] ?? 'Not specified';
    final vehicleType = ambulance['vehicleType'] ?? 'Not specified';
    final phone = ambulance['phone'] ?? 'Not available';

    final ambulanceId = (ambulance['id'] ?? ambulance['_id']).toString();

    final address = ambulance['address'] as Map<String, dynamic>?;
    final place = address?['place'] ?? '';
    final district = address?['district'] ?? '';
    final stateName = address?['state'] ?? '';
    final location =
        [place, district, stateName].where((s) => s.isNotEmpty).join(', ');
    final fullLocation = location.isEmpty ? 'Not provided' : location;

    final double iconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double textSize = _clamp(screenWidth * 0.04, 14, 20);
    final double titleSize = _clamp(screenWidth * 0.045, 16, 24);

    return Card(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          side: BorderSide(color: Colors.grey)),
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
                    style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: _clamp(screenWidth * 0.06, 24, 36)),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AmbulanceRegister(editData: ambulance),
                        ),
                      );
                      if (result != null && result['refresh'] == true) {
                        _loadAmbulances();
                      }
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(
                            "Delete Ambulance",
                            style: TextStyle(
                                fontSize: _clamp(screenWidth * 0.05, 18, 26)),
                          ),
                          content: Text(
                            "Are you sure you want to delete this ambulance record?",
                            style: TextStyle(
                                fontSize: _clamp(screenWidth * 0.04, 14, 20)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize:
                                        _clamp(screenWidth * 0.04, 14, 20)),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                "Delete",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize:
                                        _clamp(screenWidth * 0.04, 14, 20)),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final success = await ref
                            .read(ambulanceListProvider.notifier)
                            .deleteAmbulance(ambulanceId);
                        if (mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Ambulance deleted successfully",
                                style: TextStyle(
                                    fontSize:
                                        _clamp(screenWidth * 0.04, 14, 20)),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadAmbulances();
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit,
                              color: Colors.black, size: iconSize),
                          SizedBox(width: screenWidth * 0.03),
                          Text(
                            'Edit',
                            style: TextStyle(
                                fontSize: _clamp(screenWidth * 0.04, 14, 20)),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded,
                              color: Colors.black, size: iconSize),
                          SizedBox(width: screenWidth * 0.03),
                          Text(
                            'Delete',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize:
                                    _clamp(screenWidth * 0.04, 14, 20)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.008),
            Text("Service : $serviceName",
                style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700)),
            Text("Vehicle Type : $vehicleType",
                style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700)),
            Text("Phone : $phone",
                style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700)),
            Text("Location : $fullLocation",
                style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}