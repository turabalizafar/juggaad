import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../providers/orchestration_provider.dart';
import '../providers/service_providers.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;
  Position? _userPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userPosition = position;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final orchestrationNotifier = ref.watch(orchestrationProvider.notifier);
    final bookResponse = orchestrationNotifier.bookResponse;
    final selectedProviderId = orchestrationNotifier.selectedProviderId;
    
    final provider = orchestrationNotifier.searchResponse?.providers.firstWhere(
      (p) => p.id == selectedProviderId,
    );

    if (bookResponse == null || provider == null) {
      return const Scaffold(body: Center(child: Text('Tracking details unavailable.')));
    }

    final providerLatLng = LatLng(provider.lat, provider.lng);
    LatLng userLatLng = const LatLng(31.5204, 74.3587); // Default
    if (_userPosition != null) {
      userLatLng = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    }

    // Midpoint for camera
    final midLat = (userLatLng.latitude + providerLatLng.latitude) / 2;
    final midLng = (userLatLng.longitude + providerLatLng.longitude) / 2;
    final initialCameraPosition = CameraPosition(
      target: LatLng(midLat, midLng),
      zoom: 12,
    );

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('user'),
        position: userLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ),
      Marker(
        markerId: const MarkerId('provider'),
        position: providerLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: provider.name),
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Provider'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(orchestrationProvider.notifier).setIdle();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Map Background
                GoogleMap(
                  initialCameraPosition: initialCameraPosition,
                  markers: markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Fit bounds
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_mapController != null) {
                        LatLngBounds bounds;
                        if (userLatLng.latitude > providerLatLng.latitude) {
                          bounds = LatLngBounds(southwest: providerLatLng, northeast: userLatLng);
                        } else {
                          bounds = LatLngBounds(southwest: userLatLng, northeast: providerLatLng);
                        }
                        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                      }
                    });
                  },
                  myLocationEnabled: false, // Using custom marker
                  zoomControlsEnabled: false,
                ),
                
                // Top Overlay (ETA and Tracking ID)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tracking ID',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                            Text(
                              bookResponse.trackingId,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer, size: 16, color: colorScheme.onTertiaryContainer),
                              const SizedBox(width: 4),
                              Text(
                                '${bookResponse.etaMinutes} mins',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Sheet (Timeline & Actions)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Provider Info
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.secondaryContainer,
                              radius: 24,
                              child: Icon(Icons.person, color: colorScheme.secondary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '⭐ ${provider.rating.toStringAsFixed(1)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.call),
                              color: colorScheme.primary,
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Timeline
                        _buildTimeline(theme),
                        
                        const SizedBox(height: 24),
                        
                        // Actions
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final apiService = ref.read(apiServiceProvider);
                              apiService.sendFollowup(bookResponse.bookingId, 'ping');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Follow-up sent to provider.')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Send Follow-up'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimelineStep(
          theme: theme,
          title: 'Confirmed',
          icon: Icons.check_circle,
          isActive: true,
          isCompleted: true,
        ),
        Expanded(
          child: Container(
            height: 2,
            color: colorScheme.primary,
          ),
        ),
        _buildTimelineStep(
          theme: theme,
          title: 'Distance',
          icon: Icons.directions_car,
          isActive: true,
          isCompleted: false, // Current step
        ),
        Expanded(
          child: Container(
            height: 2,
            color: colorScheme.surfaceContainerHigh,
          ),
        ),
        _buildTimelineStep(
          theme: theme,
          title: 'Completed',
          icon: Icons.home_repair_service,
          isActive: false,
          isCompleted: false,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required bool isActive,
    required bool isCompleted,
  }) {
    final colorScheme = theme.colorScheme;
    final color = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? colorScheme.primary : (isActive ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isCompleted ? colorScheme.onPrimary : (isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
