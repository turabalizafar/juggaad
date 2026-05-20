import 'package:flutter/material.dart';
import '../models/parsed_intent.dart';
import '../models/provider.dart';
import '../theme/app_theme.dart';
import 'provider_results_screen.dart';

class ParsedRequestScreen extends StatefulWidget {
  final ParsedIntent initialIntent;

  const ParsedRequestScreen({super.key, required this.initialIntent});

  @override
  State<ParsedRequestScreen> createState() => _ParsedRequestScreenState();
}

class _ParsedRequestScreenState extends State<ParsedRequestScreen> {
  late TextEditingController _serviceController;
  late TextEditingController _locationController;
  late TextEditingController _urgencyController;
  late TextEditingController _issueController;

  @override
  void initState() {
    super.initState();
    _serviceController = TextEditingController(text: widget.initialIntent.serviceType);
    _locationController = TextEditingController(text: widget.initialIntent.locationText ?? '');
    _urgencyController = TextEditingController(text: widget.initialIntent.urgency);
    _issueController = TextEditingController(text: widget.initialIntent.issueSummary);
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _locationController.dispose();
    _urgencyController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Request'),
        backgroundColor: AppTheme.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.success,
            ),
            const SizedBox(height: 16),
            Text(
              "Here's what I understood",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.amethystDark,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Service Type', _serviceController, Icons.build),
                    const SizedBox(height: 16),
                    _buildTextField('Location', _locationController, Icons.location_on),
                    const SizedBox(height: 16),
                    _buildTextField('Urgency', _urgencyController, Icons.access_time),
                    const SizedBox(height: 16),
                    _buildTextField('Issue Summary', _issueController, Icons.description, maxLines: 3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Mock Top Providers
                final mockProviders = [
                  Provider(
                    id: 'p1', name: 'Usman AC Repair', phoneNumber: '+923001234567',
                    rating: 4.8, distanceKm: 2.1, etaMinutes: 15, basePrice: 500,
                    available: true, rankScore: 0.95, explanation: '',
                  ),
                  Provider(
                    id: 'p2', name: 'Ali Tech Services', phoneNumber: '+923009876543',
                    rating: 4.5, distanceKm: 3.5, etaMinutes: 25, basePrice: 400,
                    available: true, rankScore: 0.85, explanation: '',
                  ),
                  Provider(
                    id: 'p3', name: 'Rehan Cooling', phoneNumber: '+923211112222',
                    rating: 4.9, distanceKm: 5.0, etaMinutes: 40, basePrice: 600,
                    available: false, rankScore: 0.70, explanation: '',
                  ),
                ];
                
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProviderResultsScreen(
                      providers: mockProviders,
                      topReasoning: 'Usman was selected because he is the closest available technician with a top rating in your area.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal,
              ),
              child: const Text('Find Providers'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.teal),
          ),
        ),
      ],
    );
  }
}
