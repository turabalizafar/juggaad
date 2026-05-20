import 'package:flutter/material.dart';
import '../models/provider.dart';
import '../theme/app_theme.dart';
import 'booking_confirmation_screen.dart';

class ProviderResultsScreen extends StatelessWidget {
  final List<Provider> providers;
  final String topReasoning;

  const ProviderResultsScreen({
    super.key,
    required this.providers,
    required this.topReasoning,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Top Providers'),
        backgroundColor: AppTheme.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // AI Reasoning Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.amethyst),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    topReasoning,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              '${providers.length} providers found near you',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.amethystDark,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Horizontal Provider Cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final provider = providers[index];
                return _buildProviderCard(context, provider);
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context, Provider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.tealLight,
                    child: Text(
                      provider.name[0],
                      style: const TextStyle(color: AppTheme.tealDark, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: provider.available ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      provider.available ? 'Available' : 'Busy',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: provider.available ? AppTheme.success : AppTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const Spacer(),
              Text(
                provider.name,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    provider.rating.toString(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${provider.distanceKm} km away', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('ETA: ${provider.etaMinutes} mins', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.available ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookingConfirmationScreen(
                          provider: provider,
                          bookingId: 'BK-2026-085',
                          timeSlot: '10:00 AM',
                        ),
                      ),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.amethyst,
                  ),
                  child: const Text('Book Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
