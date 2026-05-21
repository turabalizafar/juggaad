import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/orchestration_provider.dart';
import 'tracking_screen.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<OrchestrationState>(orchestrationProvider, (previous, next) {
      if (next == OrchestrationState.tracking) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TrackingScreen()),
        );
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bookResponse = ref.watch(orchestrationProvider.notifier).bookResponse;

    if (bookResponse == null) {
      return const Scaffold(body: Center(child: Text('No booking details found.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        automaticallyImplyLeading: false, // Don't allow simple back
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Animation / Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Booking Confirmed!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                bookResponse.confirmationText.isNotEmpty 
                    ? bookResponse.confirmationText 
                    : 'Your provider is on the way.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              
              // Provider Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tracking ID',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                        Text(
                          bookResponse.trackingId,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
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
                                bookResponse.providerName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.timer, size: 16, color: colorScheme.tertiary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Arrives in ${bookResponse.etaMinutes} mins',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.tertiary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Actions
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    launchUrl(Uri.parse('tel:${bookResponse.providerPhone}'));
                  },
                  icon: const Icon(Icons.call),
                  label: Text('Call ${bookResponse.providerName}'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(orchestrationProvider.notifier).setTracking();
                    // Phase 6 will handle tracking
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Track Provider'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
