import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hosta/data/models/hospital-categorymodel.dart';
import 'package:hosta/presentation/screens/hospital/hospitals.dart';
import 'package:hosta/services/api_service.dart';
import 'package:hosta/services/socket-service.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

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
  late Function(dynamic) _onCategoryEvent;
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
    _onCategoryEvent = (data) async {
      if (!mounted) return;
      await fetchCategories(
        query: searchQuery.isEmpty ? null : searchQuery,
      );
    };
    SocketService().addListener(
      [
        'CATEGORY_REGISTERED',
        'CATEGORY_UPDATED',
        'CATEGORY_DELETED',
      ],
      _onCategoryEvent,
    );
  }
String toTitleCase(String text) {
  if (text.trim().isEmpty) return text;

  return text
      .trim()
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
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
          final List<Category> allCategories =
    data.map((e) => Category.fromJson(e)).toList();

final Map<String, Category> uniqueCategories = {};

for (final category in allCategories) {
  final key = category.name.trim().toLowerCase();

  if (!uniqueCategories.containsKey(key)) {
    uniqueCategories[key] = category;
  }
}

setState(() {
  categories = uniqueCategories.values.toList();
});
        });
      } else {
        setState(() => categories = []);
      }
    } catch (e) {
      // ignore
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
    SocketService().removeListener("CATEGORY_REGISTERED", _onCategoryEvent);
    SocketService().removeListener("CATEGORY_UPDATED", _onCategoryEvent);
    SocketService().removeListener("CATEGORY_DELETED", _onCategoryEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive clamped values
    final double appBarTitleSize = _clamp(screenWidth * 0.05, 16, 24);
    final double backIconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double searchBoxPadding = _clamp(screenWidth * 0.04, 12, 24);
    final double searchRadius = _clamp(screenWidth * 0.032, 8, 16);
    final double gridPadding = _clamp(screenWidth * 0.04, 12, 24);
    final double crossAxisSpacing = _clamp(screenWidth * 0.032, 8, 16);
    final double mainAxisSpacing = _clamp(screenWidth * 0.032, 8, 16);
    final double avatarRadius = _clamp(screenWidth * 0.12, 30, 70);
    final double categoryNameSize = _clamp(screenWidth * 0.035, 12, 18);
    final double emptyIconSize = _clamp(screenWidth * 0.16, 40, 80);
    final double emptyTextSize = _clamp(screenWidth * 0.043, 14, 20);
    final double cardRadius = _clamp(screenWidth * 0.032, 8, 16);
    final double cardShadowBlur = _clamp(screenWidth * 0.008, 2, 6);
    final double cardSpacingVertical = _clamp(screenHeight * 0.01, 4, 12);
    final double loadingStrokeWidth = _clamp(screenWidth * 0.008, 2, 6);

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Hospital Categories",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: appBarTitleSize,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: backIconSize,
          ),
        ),
      ),
      body: Column(
        children: [
          // ===== SEARCH =====
          Padding(
            padding: EdgeInsets.all(searchBoxPadding),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(searchRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // ===== GRID =====
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: loadingStrokeWidth,
                    ),
                  )
                : categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: emptyIconSize,
                              color: Colors.grey,
                            ),
                            SizedBox(height: _clamp(screenHeight * 0.015, 8, 20)),
                            Text(
                              searchQuery.isNotEmpty
                                  ? 'No categories found'
                                  : 'No categories available',
                              style: TextStyle(
                                fontSize: emptyTextSize,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(gridPadding),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: crossAxisSpacing,
                          mainAxisSpacing: mainAxisSpacing,
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
                              avatarRadius,
                              categoryNameSize,
                              cardRadius,
                              cardShadowBlur,
                              cardSpacingVertical,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    String name,
    String imageUrl,
    double screenWidth,
    double screenHeight,
    double avatarRadius,
    double categoryNameSize,
    double cardRadius,
    double cardShadowBlur,
    double cardSpacingVertical,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: cardShadowBlur,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
       CircleAvatar(
  radius: avatarRadius,
  backgroundColor: Colors.grey.shade200,
  child: ClipOval(
    child: imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            width: avatarRadius * 2,
            height: avatarRadius * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.local_hospital_sharp,
              size: _clamp(avatarRadius * 0.7, 20, 40),
            ),
          )
        : Icon(
            Icons.local_hospital_sharp,
            size: _clamp(avatarRadius * 0.7, 20, 40),
          ),
  ),
),
          SizedBox(height: cardSpacingVertical),
          Text(
             toTitleCase(name),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: categoryNameSize,
            ),
          ),
        ],
      ),
    );
  }
}