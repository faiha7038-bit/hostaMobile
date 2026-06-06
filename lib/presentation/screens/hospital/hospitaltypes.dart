// import 'package:flutter/material.dart';
// import 'package:hosta/presentation/screens/hospital/hospitals.dart';
// import 'package:hosta/data/constants/hospital_types_data.dart';


// class HospitalTypes extends StatefulWidget {
//   const HospitalTypes({super.key});

//   @override
//   State<HospitalTypes> createState() => _HospitalTypesState();
// }

// class _HospitalTypesState extends State<HospitalTypes> {
//   String searchQuery = '';
// //
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;

//     final filteredData = hospitalTypesData.entries
//         .where((e) => e.key.toLowerCase().contains(searchQuery.toLowerCase()))
//         .toList();

//     return Scaffold(
//       backgroundColor: const Color(0xFFECFDF5),
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         title: Text(
//           "Hospital Categories",
//           style: TextStyle(
//             fontWeight: FontWeight.bold, 
//             color: Colors.white,
//             fontSize: screenWidth * 0.05,
//           ),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(
//             Icons.arrow_back_ios_new,
//             color: Colors.white,
//             size: screenWidth * 0.055,
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//         elevation: 0,
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // ===== Search Bar =====
//             Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal: screenWidth * 0.04,
//                 vertical: screenHeight * 0.015,
//               ),
//               child: TextField(
//                 onChanged: (val) => setState(() => searchQuery = val),
//                 decoration: InputDecoration(
//                   hintText: 'Search categories...',
//                   hintStyle: TextStyle(fontSize: screenWidth * 0.035),
//                   prefixIcon: Icon(
//                     Icons.search,
//                     color: Colors.grey,
//                     size: screenWidth * 0.06,
//                   ),
//                   filled: true,
//                   fillColor: Colors.grey[100],
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.0125),
//                 ),
//               ),
//             ),

//             // ===== Grid of Hospital Types =====
//             Expanded(
//               child: GridView.builder(
//                 padding: EdgeInsets.all(screenWidth * 0.04),
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 12,
//                   mainAxisSpacing: 12,
//                   childAspectRatio: 1,
//                 ),
//                 itemCount: filteredData.length,
//                 itemBuilder: (context, index) {
//                   String name = filteredData[index].key;
//                   String imageUrl = filteredData[index].value;

//                   return GestureDetector(
//                     onTap: () {
//                       // 🧭 Navigate and pass the type name
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => Hospitals(type: name),
//                         ),
//                       );
//                     },
//                     child: _buildCard(name, imageUrl, screenWidth, screenHeight),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCard(String name, String imageUrl, double screenWidth, double screenHeight) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(screenWidth * 0.035),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircleAvatar(
//             backgroundImage: NetworkImage(imageUrl),
//             radius: screenWidth * 0.12,
//           ),
//           SizedBox(height: screenHeight * 0.01),
//           Text(
//             name,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontWeight: FontWeight.w500,
//               fontSize: screenWidth * 0.035,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//..
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hosta/data/models/hospital-categorymodel.dart';
import 'package:hosta/presentation/screens/hospital/hospitals.dart';
import 'package:hosta/services/api_service.dart';

class HospitalTypes extends StatefulWidget {
  const HospitalTypes({super.key});

  @override
  State<HospitalTypes> createState() => _HospitalTypesState();
}

class _HospitalTypesState extends State<HospitalTypes> {
  String searchQuery = '';
Timer? _debounce;
  bool isLoading = false;
  List<Category> categories = [];

  int page = 1;
  int limit = 10;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

Future<void> fetchCategories({String? query}) async {
  setState(() {
    isLoading = true;
    categories = []; // clear old results
  });
  try {
    final response = await ApiService().getCategories(
      searchQuery: query,
      page: 1,
      limit: limit,
    );
    final Map<String, dynamic> body = response.data;
    if (body['success'] == true && body['data'] != null) {
      final List data = body['data'];
      setState(() {
        categories = data.map((e) => Category.fromJson(e)).toList();
      });
    } else {
      // No results (success false or data empty)
      setState(() => categories = []);
    }
  } catch (e) {
    log("Error: $e");
  } finally {
    setState(() => isLoading = false);
  }
}

void onSearchChanged(String val) {
  setState(() {
    searchQuery = val;
  });

  if (_debounce?.isActive ?? false) _debounce!.cancel();

  _debounce = Timer(const Duration(milliseconds: 500), () {
    page = 1;
    fetchCategories(query: val);
  });
}
@override
void dispose() {
  _debounce?.cancel();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title:  Text(
          "Hospital Categories",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: screenWidth *0.05,
          ),
        ),
        centerTitle: true,
        leading: IconButton(onPressed: (){Navigator.pop(context);}, 
        icon: Icon(Icons.arrow_back_ios_new,color: Colors.white,
        size: screenWidth *0.055,
        )),
      ),

      body: Column(
        children: [
          // ===== SEARCH =====
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: TextField(
  onChanged: onSearchChanged,
  decoration: InputDecoration(
    hintText: 'Search categories...',
    prefixIcon: const Icon(Icons.search),
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
)
          ),

          // ===== GRID =====
        Expanded(
  child: isLoading
      ? const Center(
          child: CircularProgressIndicator(),
        )
      : categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    searchQuery.isNotEmpty
                        ? 'No categories found'
                        : 'No categories available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(screenWidth * 0.04),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final item = categories[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Hospitals(type: item.name),
                      ),
                    );
                  },
                  child: _buildCard(
                    item.name,
                    item.imageUrl ?? '',
                    screenWidth,
                    screenHeight,
                  ),
                );
              },
            ),
)
        ],
      ),
    );
  }

  Widget _buildCard(
    String name,
    String imageUrl,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: screenWidth * 0.12,
            backgroundImage:
                imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty ? const Icon(Icons.local_hospital_sharp) : null,
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.035,
            ),
          ),
        ],
      ),
    );
  }
}