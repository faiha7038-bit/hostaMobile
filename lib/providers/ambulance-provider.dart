import 'dart:convert';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Provider for ambulance list (state notifier)
final ambulanceListProvider = StateNotifierProvider<AmbulanceNotifier, List<dynamic>>(
  (ref) => AmbulanceNotifier(ref, ref.read(apiServiceProvider)),
);
final isOfflineProvider =
    StateProvider<bool>((ref) => false);
// Providers for UI state
final isLoadingProvider = StateProvider<bool>((ref) => true);
final searchQueryProvider = StateProvider<String>((ref) => '');
final allAmbulancesProvider =
    StateProvider<List<dynamic>>(
  (ref) => [],
);
final selectedCountryProvider = StateProvider<String>((ref) => '');
final selectedStateProvider = StateProvider<String>((ref) => '');
final selectedDistrictProvider = StateProvider<String>((ref) => '');
final selectedPlaceProvider = StateProvider<String>((ref) => '');
final ambulanceIdProvider = StateProvider<String?>((ref) => null);

class AmbulanceNotifier
    extends StateNotifier<List<dynamic>> {

  final Ref _ref;
  final ApiService _apiService;

  late Box cacheBox;



  AmbulanceNotifier(
    this._ref,
    this._apiService,
  ) : super([]) {

    cacheBox = Hive.box('ambulance_cache');
  }

  Future<bool> _hasInternet() async {
    final result =
        await Connectivity()
            .checkConnectivity();

    return result !=
        ConnectivityResult.none;
  }
// In ambulance-provider.dart – AmbulanceListNotifier.fetchAmbulances

Future<void> fetchAmbulances() async {
  try {
    final isOffline = _ref.read(isOfflineProvider);

    // ----- OFFLINE MODE -----
    if (isOffline) {
      final cached = cacheBox.get('all_ambulances');
      if (cached != null) {
        final decoded = List<dynamic>.from(jsonDecode(cached));
        state = decoded;
        _ref.read(allAmbulancesProvider.notifier).state = decoded;
      }
      _ref.read(isLoadingProvider.notifier).state = false;
      return;
    }

    // ----- ONLINE MODE: read search & location filters -----
    final searchQuery = _ref.read(searchQueryProvider);
    final country = _ref.read(selectedCountryProvider);
    final stateFilter = _ref.read(selectedStateProvider);
    final district = _ref.read(selectedDistrictProvider);
    final place = _ref.read(selectedPlaceProvider);

    // ----- API CALL with userId + all filters -----
    final response = await _apiService.getAllAmbulances(
 
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      country: country.isEmpty ? null : country,
      state: stateFilter.isEmpty ? null : stateFilter,
      district: district.isEmpty ? null : district,
      place: place.isEmpty ? null : place,
    );

    if (response.statusCode == 200 && response.data != null) {
      final newData = response.data is List
          ? response.data
          : response.data['data'] ?? [];

      // ----- SAVE TO HIVE CACHE (offline support) -----
      await cacheBox.put('all_ambulances', jsonEncode(newData));

      // ----- BUTTON FIX: Update SharedPreferences flags -----
      // final prefs = await SharedPreferences.getInstance();
      // if (newData.isNotEmpty) {
      //   final firstAmbulance = newData.first as Map<String, dynamic>;
      //   final firstId = (firstAmbulance['_id'] ?? firstAmbulance['id']).toString();
      //   await prefs.setBool('ambulanceRegistered', true);
      //   await prefs.setString('ambulanceId', firstId);
      // } else {
      //   await prefs.remove('ambulanceRegistered');
      //   await prefs.remove('ambulanceId');
      // }

      // Update UI state
      state = newData;
      _ref.read(allAmbulancesProvider.notifier).state = newData;
      log("AMBULANCE DATA => $newData");
    }
  } catch (e) {
    log("FETCH ERROR: $e – loading from cache");
    // Fallback to cache on error
    final cached = cacheBox.get('all_ambulances');
    if (cached != null) {
      final decoded = List<dynamic>.from(jsonDecode(cached));
      state = decoded;
      _ref.read(allAmbulancesProvider.notifier).state = decoded;
    } else {
      state = [];
    }
  } finally {
    _ref.read(isLoadingProvider.notifier).state = false;
  }
}
// Future<void> fetchAmbulances() async {
//   try {

//     final isOffline =
//         _ref.read(isOfflineProvider);

//     // OFFLINE
//     if (isOffline) {

//       final cached =
//           cacheBox.get('all_ambulances');

//       if (cached != null) {

//         final decoded =
//             List<dynamic>.from(
//           jsonDecode(cached),
//         );

//         state = decoded;

//         _ref
//             .read(
//               allAmbulancesProvider.notifier,
//             )
//             .state = decoded;
//       }

//       return;
//     }

//     // SEARCH + FILTER VALUES
//     final searchQuery =
//         _ref.read(searchQueryProvider);

//     final country =
//         _ref.read(selectedCountryProvider);

//     final stateFilter =
//         _ref.read(selectedStateProvider);

//     final district =
//         _ref.read(selectedDistrictProvider);

//     final place =
//         _ref.read(selectedPlaceProvider);

//     // ONLINE API CALL
//     final response =
//         await _apiService.getAllAmbulances(

//       searchQuery:
//           searchQuery.isEmpty
//               ? null
//               : searchQuery,

//       country:
//           country.isEmpty
//               ? null
//               : country,

//       state:
//           stateFilter.isEmpty
//               ? null
//               : stateFilter,

//       district:
//           district.isEmpty
//               ? null
//               : district,

//       place:
//           place.isEmpty
//               ? null
//               : place,
//     );

//     if (response.statusCode == 200 &&
//         response.data != null) {

//       final newData =
//           response.data is List
//               ? response.data
//               : response.data['data'] ?? [];

//       // SAVE CACHE
//       await cacheBox.put(
//         'all_ambulances',
//         jsonEncode(newData),
//       );

//       state = newData;

//       _ref
//           .read(
//             allAmbulancesProvider.notifier,
//           )
//           .state = newData;
//     }

//   } catch (e) {

//     log("CACHE LOAD ERROR: $e");

//     final cached =
//         cacheBox.get('all_ambulances');

//     if (cached != null) {

//       final decoded =
//           List<dynamic>.from(
//         jsonDecode(cached),
//       );

//       state = decoded;

//       _ref
//           .read(
//             allAmbulancesProvider.notifier,
//           )
//           .state = decoded;
//     }

//   } finally {

//     _ref
//         .read(isLoadingProvider.notifier)
//         .state = false;
//   }
// }




// class AmbulanceNotifier extends StateNotifier<List<dynamic>> {
//   final Ref _ref;
//   final ApiService _apiService;

//   AmbulanceNotifier(this._ref, this._apiService) : super([]);
//   // ambulance-provider.dart - inside AmbulanceNotifier

// Future<void> fetchAmbulances() async {
//   List<dynamic> newData = [];
//   try {
//     final searchQuery = _ref.read(searchQueryProvider);
//     final country = _normalize(_ref.read(selectedCountryProvider));
//     final state = _normalize(_ref.read(selectedStateProvider));
//     final district = _normalize(_ref.read(selectedDistrictProvider));
//     final place = _normalize(_ref.read(selectedPlaceProvider));

//     final response = await _apiService.getAllAmbulances(
//       // ❌ Remove serviceName: searchQuery.isEmpty ? null : searchQuery,
//       searchQuery: searchQuery.isEmpty ? null : searchQuery,  // ✅ Use searchQuery
//       country: country.isEmpty ? null : country,
//       state: state.isEmpty ? null : state,
//       district: district.isEmpty ? null : district,
//       place: place.isEmpty ? null : place,
//     );

//     log("🔍 SEARCH QUERY: $searchQuery");
//     if (response.statusCode == 200 && response.data != null) {
//       newData = response.data is List
//           ? response.data
//           : response.data['data'] ?? [];
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('cached_ambulances', jsonEncode(newData));
//     } else {
//       newData = [];
//     }
//   } catch (e) {
//     log("❌ API failed → loading from cache");
//     final prefs = await SharedPreferences.getInstance();
//     final cached = prefs.getString('cached_ambulances');
//     newData = cached != null
//         ? List<Map<String, dynamic>>.from(jsonDecode(cached))
//         : [];
//   } finally {
//     state = newData;
//     _ref.read(isLoadingProvider.notifier).state = false;
//   }
// }

// //   Future<void> fetchAmbulances() async {
// //     List<dynamic> newData = [];
// //     try {
// //       final searchQuery = _ref.read(searchQueryProvider);
// //       final country = _normalize(_ref.read(selectedCountryProvider));
// //       final state = _normalize(_ref.read(selectedStateProvider));
// //       final district = _normalize(_ref.read(selectedDistrictProvider));
// //       final place = _normalize(_ref.read(selectedPlaceProvider));

// //       final response = await _apiService.getAllAmbulances(
// //         serviceName: searchQuery.isEmpty ? null : searchQuery,
// //         country: country.isEmpty ? null : country,
// //         state: state.isEmpty ? null : state,
// //         district: district.isEmpty ? null : district,
// //         place: place.isEmpty ? null : place,
// //       );
// //  log("🔍 SEARCH QUERY: $searchQuery");
// //       if (response.statusCode == 200 && response.data != null) {
// //         newData = response.data is List
// //             ? response.data
// //             : response.data['data'] ?? [];
// //         final prefs = await SharedPreferences.getInstance();
// //         await prefs.setString('cached_ambulances', jsonEncode(newData));
// //       } else {
// //         newData = [];
// //       }
// //     } catch (e) {
// //       log("❌ API failed → loading from cache");
// //       final prefs = await SharedPreferences.getInstance();
// //       final cached = prefs.getString('cached_ambulances');
// //       newData = cached != null
// //           ? List<Map<String, dynamic>>.from(jsonDecode(cached))
// //           : [];
// //     } finally {
// //       this.state = newData;   // assign only once
// //       _ref.read(isLoadingProvider.notifier).state = false;
// //     }
// //   }

//   String _normalize(String? value) {
//     if (value == null || value.trim().isEmpty) return '';
//     final trimmed = value.trim();
//     return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
//   }
    }