import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/amb_detail-provider.dart';

class AmbulanceDetailsPage extends ConsumerWidget {
  const AmbulanceDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ambulanceProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Ambulance Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                    image: AssetImage("assets/ambulance.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoCard(context, ref),
                  const SizedBox(height: 16),
                  _buildFacilityCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ambulanceProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "KL-11-AB-1234",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(state.isAvailable ? "Available" : "Not Available"),
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
          const SizedBox(height: 10),
          const Text("Type: ICU"),
          const Text("Driver: Rahman"),
          const Text("Phone: 9876543210"),
          const Text("Location: Calicut"),
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
                .map((f) => Chip(
                      label: Text(f),
                      backgroundColor: Colors.red.shade50,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: const [
        Icon(Icons.edit, color: Colors.black),
        SizedBox(width: 10),
        Icon(Icons.delete_forever_rounded, color: Colors.black),
      ],
    );
  }
}