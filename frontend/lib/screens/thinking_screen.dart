import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TraceStep {
  final String step;
  final String message;
  final String timestamp;

  TraceStep({required this.step, required this.message, required this.timestamp});
}

class ThinkingScreen extends StatelessWidget {
  final Stream<List<TraceStep>> traceStream;
  final VoidCallback onComplete;

  const ThinkingScreen({
    super.key,
    required this.traceStream,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.teal,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'AI is thinking...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.amethystDark,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: StreamBuilder<List<TraceStep>>(
                  stream: traceStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.error));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Initializing...'));
                    }

                    final traces = snapshot.data!;
                    return ListView.builder(
                      itemCount: traces.length,
                      itemBuilder: (context, index) {
                        final trace = traces[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  trace.message,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
