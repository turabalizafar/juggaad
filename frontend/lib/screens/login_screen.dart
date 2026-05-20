import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_providers.dart';
import '../providers/profile_provider.dart';
import 'main_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final userCred = await authService.signInWithGoogle();
      
      if (userCred != null) {
        if (!mounted) return;
        // Show phone dialog
        _showPhoneDialog(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhoneDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PhoneDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.bolt,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Jugaad',
                style: textTheme.displayLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find trusted services near you',
                style: textTheme.bodyMedium,
              ),
              const Spacer(),
              // Actions
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.g_mobiledata, size: 28), 
                  label: const Text('Sign in with Google'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerLowest,
                    foregroundColor: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhoneDialog extends ConsumerStatefulWidget {
  const PhoneDialog({super.key});

  @override
  ConsumerState<PhoneDialog> createState() => _PhoneDialogState();
}

class _PhoneDialogState extends ConsumerState<PhoneDialog> {
  final _phoneController = TextEditingController(text: '+92');
  bool _isSubmitting = false;

  Future<void> _submitPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(profileProvider.notifier).updateProfile(phone);
      if (!mounted) return;
      Navigator.of(context).pop(); // Close dialog
      // Navigate to Home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.person_outline,
                size: 32,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Complete your profile',
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your phone number to continue',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text('Phone Number', style: textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.call),
                  hintText: '+92 300 0000000',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPhone,
              child: _isSubmitting 
                  ? SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary)
                    )
                  : const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
