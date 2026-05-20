import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
