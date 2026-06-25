import 'dart:convert';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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
bool _listenerAdded = false;

  final Ref _ref;
  final ApiService _apiService;

  late Box cacheBox;


  AmbulanceNotifier(
    this._ref,
    this._apiService,
  ) : super([]) {

    cacheBox = Hive.box('ambulance_cache');
      //_setupSocketListener();
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

    }