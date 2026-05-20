import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/history_request_item.dart';
import '../models/history_booking_item.dart';
import 'service_providers.dart';

final historyRequestsProvider = FutureProvider<List<HistoryRequestItem>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getHistoryRequests();
});

final historyBookingsProvider = FutureProvider<List<HistoryBookingItem>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getHistoryBookings();
});
