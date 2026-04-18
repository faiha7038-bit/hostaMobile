import 'package:flutter/material.dart';

class AmbulanceDetailsPage extends StatefulWidget {
  const AmbulanceDetailsPage({super.key});

  @override
  State<AmbulanceDetailsPage> createState() => _AmbulanceDetailsPageState();
}

class _AmbulanceDetailsPageState extends State<AmbulanceDetailsPage> {
   bool isAvailable = true;
  @override
  
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Ambulance Details", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage("assets/ambulance.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

             SizedBox(height: 16),

            // Card Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoCard(),
                 SizedBox(height: 16),
                  _buildFacilityCard(),
                SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding:  EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset:  Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "KL-11-AB-1234",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
               Row(
      children: [
        Text("Available"),
        Switch(
          value: isAvailable,
          onChanged: (val) {
            setState(() {
              isAvailable = val;
            });
          },
        ),
      ],
    ),
            ],
          ),
          SizedBox(height: 10),
          Text("Type: ICU"),
          Text("Driver: Rahman"),
          Text("Phone: 9876543210"),
          Text("Location: Calicut"),
        ],
      ),
    );
  }

  Widget _buildFacilityCard() {
    final facilities = ["Oxygen", "Ventilator", "Stretcher"];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Facilities",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: facilities
                .map(
                  (f) =>
                      Chip(label: Text(f), backgroundColor: Colors.red.shade50),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    
    return Row(
         
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.edit, color: Colors.black),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.delete_forever_rounded, color: Colors.black),
        ),
      ],
    );
  }
}
