import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juggaad/screens/booking_confirmation_screen.dart';
import '../providers/orchestration_provider.dart';

class ProviderResultsScreen extends ConsumerStatefulWidget {
  const ProviderResultsScreen({super.key});

  @override
  ConsumerState<ProviderResultsScreen> createState() =>
      _ProviderResultsScreenState();
}

class _ProviderResultsScreenState extends ConsumerState<ProviderResultsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    ref.listen<OrchestrationState>(orchestrationProvider, (previous, next) {
      if (next == OrchestrationState.confirmed) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BookingConfirmationScreen()),
        );
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final orchestrationNotifier = ref.watch(orchestrationProvider.notifier);
    final orchestrationState = ref.watch(orchestrationProvider);
    final searchResponse = orchestrationNotifier.searchResponse;

    if (searchResponse == null) {
      return const Scaffold(body: Center(child: Text('No providers found.')));
    }

    final providers = searchResponse.providers;
    final top3Reasoning = searchResponse.top3Reasoning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Providers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(orchestrationProvider.notifier).setIdle();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: Column(
        children: [
          // Reasoning Card
          if (top3Reasoning.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, color: colorScheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      top3Reasoning,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterChip('All', theme),
                const SizedBox(width: 8),
                _buildFilterChip('Nearby', theme),
                const SizedBox(width: 8),
                _buildFilterChip('Top Rated', theme),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Provider List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final provider = providers[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              provider.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  provider.rating.toStringAsFixed(1),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${provider.distanceKm.toStringAsFixed(1)} km away',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${provider.etaMinutes} mins',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (provider.explanation.isNotEmpty)
                          Text(
                            provider.explanation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: colorScheme.outline,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Base Price',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  'Rs. ${provider.basePrice}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed:
                                  provider.available &&
                                      orchestrationState !=
                                          OrchestrationState.booking
                                  ? () {
                                      ref
                                          .read(orchestrationProvider.notifier)
                                          .bookProvider(provider.id);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              child:
                                  orchestrationState ==
                                      OrchestrationState.booking
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Book Now'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ThemeData theme) {
    final isSelected = _selectedFilter == label;
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = label);
      },
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
      ),
    );
  }
}
