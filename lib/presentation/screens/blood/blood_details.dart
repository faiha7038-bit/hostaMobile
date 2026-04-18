import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/presentation/screens/blood/widgets/delete_alert.dart';
import 'package:hosta/presentation/screens/blood/donate.dart';
import 'package:hosta/providers/blood_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyBloodDetailsPage extends ConsumerStatefulWidget {
  final String userId;

  const MyBloodDetailsPage({super.key, required this.userId});

  @override
  ConsumerState<MyBloodDetailsPage> createState() =>
      _MyBloodDetailsPageState();
}

class _MyBloodDetailsPageState
    extends ConsumerState<MyBloodDetailsPage> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(bloodProvider.notifier).fetchDonor(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final donor = ref.watch(bloodProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Blood Details",
          style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        centerTitle: true,
          leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),

      body: donor == null
          ? _noDonorUI(context)
          : _donorUI(context, donor),
    );
  }

  /// 🔹 NO DONOR UI
  Widget _noDonorUI(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bloodtype, size: 60),
              const SizedBox(height: 10),

              const Text(
                "No Donor Profile Found",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => Donate()),
                  );
                },
                child: const Text("Register as Donor"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 DONOR UI
  Widget _donorUI(BuildContext context, Map<String, dynamic> donor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Blood Donation Details",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const Divider(),

              Text("Blood Group: ${donor['bloodGroup'] ?? '-'}"),
              Text("Phone: ${donor['phone'] ?? '-'}"),

              const SizedBox(height: 8),

              Text(
                "DOB: ${donor['dateOfBirth']?.toString().split('T').first ?? '-'}",
              ),

              const SizedBox(height: 8),

              Text(
                "Address: ${donor['address']?['place'] ?? ''}, "
                "${donor['address']?['district'] ?? ''}, "
                "${donor['address']?['state'] ?? ''}",
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  /// 🔹 DELETE
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      deleteAlert(
                        context,
                        onConfirm: () async {
                          await ref
                              .read(bloodProvider.notifier)
                              .deleteDonor();

                          final prefs =
                              await SharedPreferences.getInstance();
                          await prefs.remove('bloodId');

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Deleted Successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}