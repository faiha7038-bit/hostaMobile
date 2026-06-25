
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hosta/data/models/hospital-categorymodel.dart';
import 'package:hosta/presentation/screens/hospital/hospitals.dart';
import 'package:hosta/services/api_service.dart';
import 'package:hosta/services/socket-service.dart';

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
bool _listenerAdded = false;
  int page = 1;
  int limit = 10;

  @override
  void initState() {
    super.initState();
    fetchCategories();
     _setupSocketListener(); 
  }
void _setupSocketListener() {
  if (_listenerAdded) return;

  _listenerAdded = true;

  SocketService().addListener(
    [
      'CATEGORY_REGISTERED',
      'CATEGORY_UPDATED',
      'CATEGORY_DELETED',
    ],
    (data) async {
      if (!mounted) return;

      log("🏥 CATEGORY EVENT => $data");

      await fetchCategories(
        query: searchQuery.isEmpty ? null : searchQuery,
      );
    },
  );
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