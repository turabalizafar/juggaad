import 'package:flutter/material.dart';
import '../models/parsed_intent.dart';
import '../theme/app_theme.dart';

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
                // TODO: POST /search
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Finding Providers...')),
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
