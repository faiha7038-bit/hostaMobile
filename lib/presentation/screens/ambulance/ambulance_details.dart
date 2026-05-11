import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/amb_detail-provider.dart';

class AmbulanceDetailsPage extends ConsumerWidget {
  const AmbulanceDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final state = ref.watch(ambulanceProvider);

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
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: screenWidth * 0.055,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.02),
              child: Container(
                width: double.infinity,
                height: screenHeight * 0.28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  image: const DecorationImage(
                    image: AssetImage("assets/ambulance.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  _buildInfoCard(context, ref, screenWidth, screenHeight),
                  SizedBox(height: screenHeight * 0.02),
                  _buildFacilityCard(screenWidth, screenHeight),
                  SizedBox(height: screenHeight * 0.02),
                  _buildActionButtons(screenWidth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, WidgetRef ref, double screenWidth, double screenHeight) {
    final state = ref.watch(ambulanceProvider);

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: screenWidth * 0.025,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ FIXED ROW
          Row(
            children: [
              Expanded(
                child: Text(
                  "KL-11-AB-1234",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.isAvailable ? "Available" : "Not Available",
                    style: TextStyle(fontSize: screenWidth * 0.035),
                  ),
                  Switch(
                    value: state.isAvailable,
                    onChanged: (val) {
                      ref
                          .read(ambulanceProvider.notifier)
                          .toggleAvailability(val);
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.0125),
          Text(
            "Type: ICU",
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
          Text(
            "Driver: Rahman",
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
          Text(
            "Phone: 9876543210",
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
          Text(
            "Location: Calicut",
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(double screenWidth, double screenHeight) {
    final facilities = ["Oxygen", "Ventilator", "Stretcher"];

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: screenWidth * 0.025,
          ),
        ],
      ),
      child: Column( 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Facilities",
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenHeight * 0.0125),
          Wrap(
            spacing: screenWidth * 0.02,
            runSpacing: screenHeight * 0.01,
            children: facilities
                .map((f) => Chip(
                      label: Text(
                        f,
                        style: TextStyle(fontSize: screenWidth * 0.035),
                      ),
                      backgroundColor: Colors.red.shade50,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(Icons.edit, color: Colors.black, size: screenWidth * 0.06),
        SizedBox(width: screenWidth * 0.025),
        Icon(
          Icons.delete_forever_rounded,
          color: Colors.black,
          size: screenWidth * 0.06,
        ),
      ],
    );
  }
}