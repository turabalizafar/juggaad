import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/orchestration_provider.dart';
import 'provider_results_screen.dart';

class ParsedRequestScreen extends ConsumerWidget {
  const ParsedRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<OrchestrationState>(orchestrationProvider, (previous, next) {
      if (next == OrchestrationState.providerResults) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProviderResultsScreen()),
        );
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final parseResponse = ref.watch(orchestrationProvider.notifier).parseResponse;
    final orchestrationState = ref.watch(orchestrationProvider);

    if (parseResponse == null) {
      return const Scaffold(body: Center(child: Text('No parsed request found.')));
    }

    final intent = parseResponse.intent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(orchestrationProvider.notifier).setIdle();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We understood your request as follows:',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _buildField(
              context: context,
              label: 'Service Type',
              value: intent.serviceType,
              icon: Icons.build,
            ),
            _buildField(
              context: context,
              label: 'Location',
              value: intent.locationText,
              icon: Icons.location_on,
            ),
            _buildField(
              context: context,
              label: 'Urgency',
              value: intent.urgency,
              icon: Icons.timer,
            ),
            _buildField(
              context: context,
              label: 'Issue',
              value: intent.issueSummary,
              icon: Icons.description,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(orchestrationProvider.notifier).setIdle();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Prompt'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: orchestrationState == OrchestrationState.searching ? null : () {
                  ref.read(orchestrationProvider.notifier).searchProviders();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: orchestrationState == OrchestrationState.searching
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : const Text('Find Providers'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
