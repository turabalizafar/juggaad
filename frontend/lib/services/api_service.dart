import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/parse_response.dart';
import '../models/search_response.dart';
import '../models/book_response.dart';
import '../models/booking_status.dart';
import '../models/followup_response.dart';
import '../models/history_request_item.dart';
import '../models/history_booking_item.dart';
import '../models/user_profile.dart';

class ApiService {
  late final Dio _dio;
  // Use 10.0.2.2 for Android emulator to connect to localhost backend
  // For physical devices or iOS, change this to your machine's local IP (e.g. 192.168.1.10)
  final String _baseUrl = 'http://10.0.2.2:8000/api/v1';

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
    ));
  }

  Future<ParseResponse> parseRequest({
    required String rawText,
    String? languageHint,
    double? userLat,
    double? userLng,
  }) async {
    final response = await _dio.post('/parse', data: {
      'raw_text': rawText,
      if (languageHint != null) 'language_hint': languageHint,
      if (userLat != null) 'user_lat': userLat,
      if (userLng != null) 'user_lng': userLng,
    });
    return ParseResponse.fromJson(response.data);
  }

  Future<SearchResponse> searchProviders({
    required String requestId,
    required String serviceType,
    required String locationText,
    required double userLat,
    required double userLng,
    required String urgency,
  }) async {
    final response = await _dio.post('/search', data: {
      'request_id': requestId,
      'service_type': serviceType,
      'location_text': locationText,
      'user_lat': userLat,
      'user_lng': userLng,
      'urgency': urgency,
    });
    return SearchResponse.fromJson(response.data);
  }

  Future<BookResponse> bookProvider({
    required String requestId,
    required String providerId,
    String? userPhoneNumber,
    required String timeSlot,
  }) async {
    final response = await _dio.post('/book', data: {
      'request_id': requestId,
      'provider_id': providerId,
      if (userPhoneNumber != null) 'user_phone_number': userPhoneNumber,
      'time_slot': timeSlot,
    });
    return BookResponse.fromJson(response.data);
  }

  Future<BookingStatusResponse> getBookingStatus(String bookingId) async {
    final response = await _dio.get('/booking/$bookingId');
    return BookingStatusResponse.fromJson(response.data);
  }

  Future<FollowupResponse> sendFollowup(String bookingId, String trigger) async {
    final response = await _dio.post('/followup', data: {
      'booking_id': bookingId,
      'trigger': trigger,
    });
    return FollowupResponse.fromJson(response.data);
  }

  Future<List<HistoryRequestItem>> getHistoryRequests() async {
    final response = await _dio.get('/history/requests');
    final data = response.data['requests'] as List<dynamic>;
    return data.map((e) => HistoryRequestItem.fromJson(e)).toList();
  }

  Future<List<HistoryBookingItem>> getHistoryBookings() async {
    final response = await _dio.get('/history/bookings');
    final data = response.data['bookings'] as List<dynamic>;
    return data.map((e) => HistoryBookingItem.fromJson(e)).toList();
  }

  Future<UserProfile> putProfile(String phoneNumber, {String? displayName}) async {
    final response = await _dio.put('/profile', data: {
      'phone_number': phoneNumber,
      if (displayName != null) 'display_name': displayName,
    });
    return UserProfile.fromJson(response.data);
  }

  Future<UserProfile> getProfile() async {
    final response = await _dio.get('/profile');
    return UserProfile.fromJson(response.data);
  }
}
