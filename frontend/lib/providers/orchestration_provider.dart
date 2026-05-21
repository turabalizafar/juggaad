import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/parse_response.dart';
import '../models/search_response.dart';
import '../models/book_response.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'service_providers.dart';

enum OrchestrationState {
  idle,
  parsing,
  parsedPreview,
  searching,
  providerResults,
  booking,
  confirmed,
  tracking,
}

class OrchestrationNotifier extends StateNotifier<OrchestrationState> {
  final Ref _ref;
  OrchestrationNotifier(this._ref) : super(OrchestrationState.idle);

  String? currentRequestId;
  String? selectedProviderId;
  ParseResponse? parseResponse;
  SearchResponse? searchResponse;
  BookResponse? bookResponse;
  double? searchOriginLat;
  double? searchOriginLng;

  void setIdle() {
    currentRequestId = null;
    selectedProviderId = null;
    parseResponse = null;
    searchResponse = null;
    bookResponse = null;
    searchOriginLat = null;
    searchOriginLng = null;
    state = OrchestrationState.idle;
  }

  void setParsing() => state = OrchestrationState.parsing;

  void setParsedPreview(ParseResponse response) {
    currentRequestId = response.requestId;
    parseResponse = response;
    state = OrchestrationState.parsedPreview;
  }

  void setSearching() => state = OrchestrationState.searching;

  void setProviderResults(SearchResponse response) {
    searchResponse = response;
    state = OrchestrationState.providerResults;
  }

  void setBooking() => state = OrchestrationState.booking;

  void setConfirmed(BookResponse response) {
    bookResponse = response;
    state = OrchestrationState.confirmed;
  }

  void setTracking() => state = OrchestrationState.tracking;

  Future<void> searchProviders() async {
    if (parseResponse == null || currentRequestId == null) return;
    setSearching();
    try {
      final locationService = _ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      
      final apiService = _ref.read(apiServiceProvider);
      final searchLat = position?.latitude ?? 31.5204;
      final searchLng = position?.longitude ?? 74.3587;
      final response = await apiService.searchProviders(
        requestId: currentRequestId!,
        serviceType: parseResponse!.intent.serviceType,
        locationText: parseResponse!.intent.locationText,
        userLat: searchLat,
        userLng: searchLng,
        urgency: parseResponse!.intent.urgency,
      );
      
      // Use the geocoded coordinates from the backend (if available)
      // These are the ACTUAL location the user asked about, not device GPS
      searchOriginLat = response.searchOriginLat ?? searchLat;
      searchOriginLng = response.searchOriginLng ?? searchLng;
      
      setProviderResults(response);
    } catch (e) {
      setIdle();
    }
  }

  Future<void> bookProvider(String providerId) async {
    if (currentRequestId == null || searchResponse == null) return;
    setBooking();
    try {
      selectedProviderId = providerId;
      
      final provider = searchResponse!.providers.firstWhere((p) => p.id == providerId);
      final agreedEta = provider.etaMinutes;

      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.bookProvider(
        requestId: currentRequestId!,
        providerId: providerId,
        timeSlot: 'ASAP',
        agreedEtaMinutes: agreedEta,
      );
      setConfirmed(response);
    } catch (e) {
      setIdle();
    }
  }
}

final orchestrationProvider =
    StateNotifierProvider<OrchestrationNotifier, OrchestrationState>((ref) {
      return OrchestrationNotifier(ref);
    });
