import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parse_response.dart';
import '../models/search_response.dart';
import '../models/book_response.dart';

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
  OrchestrationNotifier() : super(OrchestrationState.idle);

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
}

final orchestrationProvider = StateNotifierProvider<OrchestrationNotifier, OrchestrationState>((ref) {
  return OrchestrationNotifier();
});
