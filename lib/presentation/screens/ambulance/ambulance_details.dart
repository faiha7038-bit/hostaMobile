import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AmbulanceDetailsPage extends StatefulWidget {
  final String userId;

  const AmbulanceDetailsPage({super.key, required this.userId});

  @override
  State<AmbulanceDetailsPage> createState() =>
      _AmbulanceDetailsPageState();
}

class _AmbulanceDetailsPageState extends State<AmbulanceDetailsPage> {
  final ApiService apiService = ApiService();

  Map<String, dynamic>? ambulance;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAmbulance();
  }

  Future<void> fetchAmbulance() async {
    try {
      final response =
          await apiService.getMyAmbulance(widget.userId);

      if (response.statusCode == 200 &&
          response.data["status"] == "Success") {
        setState(() {
          ambulance = response.data["data"];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Ambulance",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        backgroundColor: Colors.green,
         leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ambulance == null
              ? const Center(child: Text("No ambulance registered"))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ambulance!["serviceName"] ?? "Unknown",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      Text("Vehicle: ${ambulance!["vehicleType"]}"),
                      Text("Phone: ${ambulance!["phone"]}"),

                      const SizedBox(height: 10),

                      Text(
                        "${ambulance!["address"]?["place"] ?? ""}, "
                        "${ambulance!["address"]?["district"] ?? ""}, "
                        "${ambulance!["address"]?["state"] ?? ""}, "
                        "${ambulance!["address"]?["country"] ?? ""}",
                      ),
                    ],
                  ),
                ),
    );
  }
  
}