import 'dart:developer';

import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class MyBloodDetailsPage extends StatefulWidget {
  final String userId;

  const MyBloodDetailsPage({super.key, required this.userId});

  @override
  State<MyBloodDetailsPage> createState() =>
      _MyBloodDetailsPageState();
}

class _MyBloodDetailsPageState extends State<MyBloodDetailsPage> {
  final ApiService apiService = ApiService();

  Map<String, dynamic>? donor;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMyDonor();
  }
Future<void> fetchMyDonor() async {
  try {
    final response =
        await apiService.getADonor(widget.userId);
        log("USER ID: ${widget.userId}");
log("RESPONSE: ${response.data}");

    if (response.statusCode == 200) {
      setState(() {
        donor = response.data;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  } catch (e) {
    print("Error: $e");
    setState(() => isLoading = false);
    
  }
  
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Blood Details",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        backgroundColor: Colors.red,
         leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : donor == null
              ? const Center(child: Text("Not registered as donor"))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                         Container(
                          width: double.infinity,
                         decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade200,
                         ),
                        
                         child: SingleChildScrollView(
                           child: Padding(
                             padding: const EdgeInsets.all(8.0),
                             child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                         
                                                 Text(
                                                     donor!["name"] ?? "",
                                                     style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                                                   ),
                                                   Text(
                                                     donor!["bloodGroup"] ?? "",
                                                     style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                                                   ),
                                                   const SizedBox(height: 10),
                             
                                                  Text("Phone: ${donor!["phone"] ?? ""}"),
                             
                                                   const SizedBox(height: 10),
                             
                                                   Text(
                                                     "${donor!["address"]?["place"]}, "
                                                     "${donor!["address"]?["district"]}, "
                                                     "${donor!["address"]?["state"]}",
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
}