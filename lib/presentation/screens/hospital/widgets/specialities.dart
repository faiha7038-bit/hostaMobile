import 'package:flutter/material.dart';

class SpecialtiesTab extends StatelessWidget {
  final Map<String, dynamic> hospital;
  final Function(String) onSpecialtyTap;

  const SpecialtiesTab({
    super.key,
    required this.hospital,
    required this.onSpecialtyTap,
  });

  @override
  Widget build(BuildContext context) {
    final specialties = hospital["specialties"] as List? ?? [];
    
    if (specialties.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No specialties available",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: specialties.length,
      itemBuilder: (context, index) {
        final specialty = specialties[index];
        final specialtyName = specialty["name"] ?? "Unnamed Specialty";
        final doctorsCount = (specialty["doctors"] as List? ?? []).length;
        
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => onSpecialtyTap(specialtyName),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          specialtyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            color: Color.fromARGB(255, 12, 94, 15),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                  
                  if (specialty["description"] != null && specialty["description"].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        specialty["description"],
                      ),
                    ),
                  
                  if (specialty["department_info"] != null && specialty["department_info"].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Department: ${specialty["department_info"]}",
                        style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                      ),
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.medical_services, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          "$doctorsCount doctors available",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "View Doctors",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}