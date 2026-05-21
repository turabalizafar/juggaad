import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/orchestration_provider.dart';
import '../providers/service_providers.dart';
import '../providers/history_provider.dart';

enum TrackingPhase { waiting, arrived, inProgress, completed }

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;
  TrackingPhase _phase = TrackingPhase.waiting;
  int _rating = 0;

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
    // Use the search origin coordinates (the location from the prompt) rather than live GPS
    final userLatLng = LatLng(
      orchestrationNotifier.searchOriginLat ?? 31.5204,
      orchestrationNotifier.searchOriginLng ?? 74.3587,
    );

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
        infoWindow: const InfoWindow(title: 'Service Location'),
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
        title: Text(_phase == TrackingPhase.completed ? 'Service Complete' : 'Track Provider'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Invalidate history cache so the booking appears when user checks history
            ref.invalidate(historyBookingsProvider);
            ref.read(orchestrationProvider.notifier).setIdle();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: Stack(
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
                        if (userLatLng.latitude == providerLatLng.latitude &&
                            userLatLng.longitude == providerLatLng.longitude) {
                          return;
                        }
                        final swLat = userLatLng.latitude < providerLatLng.latitude ? userLatLng.latitude : providerLatLng.latitude;
                        final swLng = userLatLng.longitude < providerLatLng.longitude ? userLatLng.longitude : providerLatLng.longitude;
                        final neLat = userLatLng.latitude > providerLatLng.latitude ? userLatLng.latitude : providerLatLng.latitude;
                        final neLng = userLatLng.longitude > providerLatLng.longitude ? userLatLng.longitude : providerLatLng.longitude;
                        final bounds = LatLngBounds(
                          southwest: LatLng(swLat, swLng),
                          northeast: LatLng(neLat, neLng),
                        );
                        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                      }
                    });
                  },
                  myLocationEnabled: false,
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
                            color: _phase == TrackingPhase.completed 
                                ? colorScheme.primaryContainer
                                : colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _phase == TrackingPhase.completed 
                                    ? Icons.check_circle 
                                    : Icons.timer, 
                                size: 16, 
                                color: _phase == TrackingPhase.completed 
                                    ? colorScheme.primary 
                                    : colorScheme.onTertiaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _phase == TrackingPhase.completed 
                                    ? 'Done' 
                                    : '~${bookResponse.etaMinutes} mins',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: _phase == TrackingPhase.completed 
                                      ? colorScheme.primary 
                                      : colorScheme.onTertiaryContainer,
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
                              onPressed: () {
                                launchUrl(Uri.parse('tel:${provider.phoneNumber}'));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Timeline
                        _buildTimeline(theme),
                        
                        const SizedBox(height: 24),
                        
                        // Phase-dependent actions
                        _buildPhaseActions(theme, bookResponse.bookingId),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPhaseActions(ThemeData theme, String bookingId) {
    final colorScheme = theme.colorScheme;

    switch (_phase) {
      case TrackingPhase.waiting:
        return Column(
          children: [
            // Send follow-up
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final apiService = ref.read(apiServiceProvider);
                  apiService.sendFollowup(bookingId, 'pre_arrival');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Follow-up sent to provider.')),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Follow-up'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Mark as arrived
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _phase = TrackingPhase.arrived);
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Provider Has Arrived'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );

      case TrackingPhase.arrived:
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Provider has arrived!',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _phase = TrackingPhase.inProgress);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Service Started'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.tertiary,
                  foregroundColor: colorScheme.onTertiary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );

      case TrackingPhase.inProgress:
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.engineering, color: colorScheme.onTertiaryContainer),
                  const SizedBox(width: 12),
                  Text(
                    'Service in progress...',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _phase = TrackingPhase.completed);
                },
                icon: const Icon(Icons.check),
                label: const Text('Mark as Completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );

      case TrackingPhase.completed:
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.star, size: 32, color: colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'How was the service?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => _rating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            size: 36,
                            color: index < _rating ? Colors.amber : colorScheme.outline,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _rating > 0 ? () {
                  // Send completion followup
                  final apiService = ref.read(apiServiceProvider);
                  apiService.sendFollowup(bookingId, 'completed');
                  
                  // Invalidate history so it refetches with updated status
                  ref.invalidate(historyBookingsProvider);
                  ref.read(orchestrationProvider.notifier).setIdle();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thank you for rating! ($_rating/5 stars)'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                } : null,
                icon: const Icon(Icons.home),
                label: const Text('Submit & Go Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildTimeline(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final phaseIndex = _phase.index; // 0=waiting, 1=arrived, 2=inProgress, 3=completed
    
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
          title: 'En Route',
          icon: Icons.directions_car,
          isActive: phaseIndex >= 0,
          isCompleted: phaseIndex >= 1,
        ),
        Expanded(
          child: Container(
            height: 2,
            color: phaseIndex >= 2 ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          ),
        ),
        _buildTimelineStep(
          theme: theme,
          title: 'Completed',
          icon: Icons.home_repair_service,
          isActive: phaseIndex >= 2,
          isCompleted: phaseIndex >= 3,
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
