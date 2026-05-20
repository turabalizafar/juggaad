import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';
import '../models/history_booking_item.dart';

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final historyBookings = ref.watch(historyBookingsProvider);
    final historyRequests = ref.watch(historyRequestsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header matching Stitch design
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
              child: Text(
                'Booking History',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                'Review your past service requests and clever fixes.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // Bookings List
            Expanded(
              child: historyBookings.when(
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: colorScheme.outlineVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No bookings yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your service history will appear here.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      return _BookingCard(booking: bookings[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load history',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => ref.invalidate(historyBookingsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final HistoryBookingItem booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusNormalized = booking.status.toLowerCase();

    // Match Stitch: status badge colors
    Color badgeBg;
    Color badgeFg;
    if (statusNormalized == 'completed') {
      badgeBg = colorScheme.primary; // Teal #006768
      badgeFg = colorScheme.onPrimary;
    } else if (statusNormalized == 'cancelled') {
      badgeBg = colorScheme.error; // Red #BA1A1A
      badgeFg = colorScheme.onError;
    } else {
      badgeBg = colorScheme.outline; // Grey #6D7979
      badgeFg = colorScheme.onPrimary;
    }

    // Match Stitch: icon container bg per status
    Color iconBg;
    Color iconFg;
    if (statusNormalized == 'completed') {
      iconBg = colorScheme.secondaryContainer; // #C4EAE9
      iconFg = colorScheme.onSecondaryContainer; // #486A6A
    } else if (statusNormalized == 'cancelled') {
      iconBg = colorScheme.errorContainer; // #FFDAD6
      iconFg = colorScheme.onErrorContainer; // #93000A
    } else {
      iconBg = colorScheme.surfaceContainerHighest; // #DFE3E3
      iconFg = colorScheme.onSurfaceVariant; // #3D4949
    }

    // Map service type to icon
    IconData serviceIcon = _getServiceIcon(booking.serviceType);

    // Cleverness rank bar (simulated from 1-5)
    final int cleverness = statusNormalized == 'completed' ? _getCleverness(booking.serviceType) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow, // #F0F4F4
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Top Row: Icon + Title + Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Icon Container (48x48 rounded-xl)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(serviceIcon, color: iconFg),
              ),
              const SizedBox(width: 12),
              // Service Type + Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatServiceType(booking.serviceType),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(booking.createdAt),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge (pill)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                    color: badgeFg,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),

          // Bottom Row: Provider Name + Cleverness Bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Provider Name
                Row(
                  children: [
                    Icon(
                      statusNormalized == 'cancelled' || booking.providerName.isEmpty
                          ? Icons.person_off
                          : Icons.engineering,
                      size: 18,
                      color: statusNormalized == 'completed'
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      booking.providerName.isNotEmpty
                          ? booking.providerName
                          : 'Waiting for provider',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: statusNormalized == 'completed'
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: statusNormalized == 'completed'
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                        fontStyle: booking.providerName.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        decoration: statusNormalized == 'cancelled'
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                // Cleverness Rank Bar (only for completed)
                if (cleverness > 0)
                  Row(
                    children: List.generate(5, (i) {
                      return Container(
                        width: 12,
                        height: 4,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: i < cleverness
                              ? colorScheme.tertiary // Amethyst #7543A7
                              : colorScheme.surfaceContainerHighest, // #DFE3E3
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String serviceType) {
    final lower = serviceType.toLowerCase();
    if (lower.contains('plumb')) return Icons.plumbing;
    if (lower.contains('electric')) return Icons.electrical_services;
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit;
    if (lower.contains('clean')) return Icons.cleaning_services;
    if (lower.contains('carpent')) return Icons.handyman;
    if (lower.contains('paint')) return Icons.format_paint;
    return Icons.build;
  }

  String _formatServiceType(String serviceType) {
    // Capitalize first letter of each word
    return serviceType.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return 'Unknown date';
    try {
      final date = DateTime.parse(isoDate);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $ampm';
    } catch (_) {
      return isoDate;
    }
  }

  int _getCleverness(String serviceType) {
    // Generate a pseudo-cleverness based on service type hash for demo
    return (serviceType.hashCode.abs() % 5) + 1;
  }
}
