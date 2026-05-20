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
  ParseResponse? parseResponse;
  SearchResponse? searchResponse;
  BookResponse? bookResponse;

  void setIdle() {
    currentRequestId = null;
    parseResponse = null;
    searchResponse = null;
    bookResponse = null;
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
      final response = await apiService.searchProviders(
        requestId: currentRequestId!,
        serviceType: parseResponse!.intent.serviceType,
        locationText: parseResponse!.intent.locationText,
        userLat: position?.latitude ?? 31.5204, // Default to Lahore
        userLng: position?.longitude ?? 74.3587,
        urgency: parseResponse!.intent.urgency,
      );
      
      setProviderResults(response);
    } catch (e) {
      setIdle();
    }
  }

  Future<void> bookProvider(String providerId) async {
    if (currentRequestId == null) return;
    setBooking();
    try {
      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.bookProvider(
        requestId: currentRequestId!,
        providerId: providerId,
        timeSlot: 'ASAP',
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
