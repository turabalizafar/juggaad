import 'package:flutter/material.dart';
import '../models/provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Provider provider;
  final String bookingId;
  final String timeSlot;

  const BookingConfirmationScreen({
    super.key,
    required this.provider,
    required this.bookingId,
    required this.timeSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        backgroundColor: AppTheme.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Don't allow back to search
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.success,
            ),
            const SizedBox(height: 16),
            Text(
              'Your Booking is Confirmed!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.amethystDark,
              ),
            ),
            const SizedBox(height: 32),
            
            // Card A: Booking Receipt
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Receipt',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(height: 32),
                    _buildReceiptRow(context, 'Booking ID', bookingId),
                    const SizedBox(height: 12),
                    _buildReceiptRow(context, 'Technician', provider.name),
                    const SizedBox(height: 12),
                    _buildReceiptRow(context, 'Time Slot', timeSlot),
                    const SizedBox(height: 12),
                    _buildReceiptRow(context, 'Estimated Price', 'Rs. ${provider.basePrice}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Card B: Tracking / Map Placeholder
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.map, color: AppTheme.teal),
                        const SizedBox(width: 8),
                        Text('Live Tracking', style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppTheme.tealLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
                      ),
                      child: const Center(
                        child: Text('Google Maps Placeholder\n(Distance: 2.1 km)', textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ETA: ${provider.etaMinutes} minutes',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Card C: Follow-up Simulator
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active, color: AppTheme.amethyst),
                        const SizedBox(width: 8),
                        Text('Automated Follow-up', style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Text(
                        'SMS Draft Queued: "Your booking with ${provider.name} is confirmed for $timeSlot. Tracking ID: $bookingId."',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal,
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary)),
        Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
