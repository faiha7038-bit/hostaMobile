import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/presentation/screens/blood/donate.dart';
import 'package:hosta/providers/blood_details_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyBloodDetailsPage extends ConsumerStatefulWidget {
  const MyBloodDetailsPage({super.key});

  @override
  ConsumerState<MyBloodDetailsPage> createState() => _MyBloodDetailsPageState();
}

class _MyBloodDetailsPageState extends ConsumerState<MyBloodDetailsPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDonor();
  }

  Future<void> _loadDonor() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      await ref.read(bloodProvider.notifier).fetchDonor(userId);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final donor = ref.watch(bloodProvider); // single donor map or null

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Blood Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
          ),
        ),
        backgroundColor: Colors.red,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: screenWidth * 0.055),
        ),
        // Removed actions – the add icon is now a FloatingActionButton
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : donor == null
              ? _noDonorUI(context, screenWidth, screenHeight)
              : _donorCard(donor, screenWidth, screenHeight),
     
    );
  }

  Widget _noDonorUI(BuildContext context, double screenWidth, double screenHeight) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(screenWidth * 0.04),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bloodtype, size: screenWidth * 0.15, color: Colors.red),
              SizedBox(height: screenHeight * 0.0125),
              Text(
                "No Donor Profile Found",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                ),
              ),
              SizedBox(height: screenHeight * 0.0125),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Donate()),
                  );
                  if (result == true) _loadDonor();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenHeight * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Register as Donor",
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _donorCard(Map<String, dynamic> donor, double screenWidth, double screenHeight) {
    final name = donor['name'] ?? 'Not specified';
   final dobRaw = donor['dateOfBirth'];

final dateOfBirth = dobRaw != null
    ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dobRaw))
    : "Not specified";
    final bloodGroup = donor['bloodGroup'] ?? 'Not specified';
    final phone = donor['phone'] ?? 'Not available';
    final address = donor['address'] as Map<String, dynamic>?;
    final place = address?['place'] ?? '';
    final district = address?['district'] ?? '';
    final stateName = address?['state'] ?? '';
    final location = [place, district, stateName].where((s) => s.isNotEmpty).join(', ');
    final fullLocation = location.isEmpty ? 'Not provided' : location;

    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04),
        side: BorderSide(color: Colors.grey)
        ),
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
                      bloodGroup,
                      style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold,color: Colors.red),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: screenWidth * 0.06),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Donate(editData: donor),
                          ),
                        );
                        if (result == true) _loadDonor();
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Delete Donor"),
                            content: const Text(
                              "Are you sure you want to delete this donor record?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx, false);
                                },
                                child: const Text("Cancel",style: TextStyle(color: Colors.grey),),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx, true);
                                },
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(bloodProvider.notifier).deleteDonor();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Donor deleted successfully"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadDonor(); // reload (will become null)
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
                            Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Text('Delete',style: TextStyle(color: Colors.red),),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.008),
              Text("Name : $name", style: TextStyle(fontSize: screenWidth * 0.04,color: Colors.black,fontWeight: FontWeight.w500)),
              Text("D.O.B : $dateOfBirth", style: TextStyle(fontSize: screenWidth * 0.04,color: Colors.black,fontWeight: FontWeight.w500)),
              Text("Phone: $phone", style: TextStyle(fontSize: screenWidth * 0.04,color: Colors.black,fontWeight: FontWeight.w500)),
              Text("Location: $fullLocation", style: TextStyle(fontSize: screenWidth * 0.04,color: Colors.black,fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}