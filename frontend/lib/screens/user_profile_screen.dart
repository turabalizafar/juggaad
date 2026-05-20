import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_provider.dart';
import '../providers/service_providers.dart';
import 'login_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final profileState = ref.watch(profileProvider);

    // Populate controllers when data arrives
    profileState.whenData((profile) {
      if (profile != null && !_isEditing) {
        if (_nameController.text.isEmpty) {
          _nameController.text = profile.displayName ?? firebaseUser?.displayName ?? '';
        }
        if (_phoneController.text.isEmpty) {
          _phoneController.text = profile.phoneNumber;
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Hero Avatar Section
                // Matches Stitch: py-xl (32px), centered column
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      // Avatar with edit button overlay
                      // Matches Stitch: w-32 h-32 rounded-full border-4 border-surface-container-highest
                      Stack(
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surfaceContainerHighest,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF737878).withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: firebaseUser?.photoURL != null
                                  ? Image.network(
                                      firebaseUser!.photoURL!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildAvatarFallback(colorScheme),
                                    )
                                  : _buildAvatarFallback(colorScheme),
                            ),
                          ),
                          // Edit button
                          // Matches Stitch: absolute bottom-0 right-0 bg-primary text-white p-2 rounded-full
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 18,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Name + subtitle
                      // Matches Stitch: mt-md, text-headline-md, text-body-md
                      const SizedBox(height: 16),
                      Text(
                        firebaseUser?.displayName ?? 'User',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Premium Member',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // User Information Card
                // Matches Stitch: bg-surface-container-lowest rounded-xl p-lg custom-shadow border border-outline-variant/30 space-y-md
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF737878).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Full Name field
                      _buildInfoField(
                        context: context,
                        label: 'Full Name',
                        icon: Icons.person,
                        controller: _nameController,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),
                      // Phone Number field
                      _buildInfoField(
                        context: context,
                        label: 'Phone Number',
                        icon: Icons.call,
                        controller: _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      // Email Address field (read-only from Firebase)
                      _buildInfoFieldReadOnly(
                        context: context,
                        label: 'Email Address',
                        icon: Icons.mail,
                        value: firebaseUser?.email ?? 'Not available',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Settings Card
                // Matches Stitch: bg-surface-container-lowest rounded-xl p-lg custom-shadow border border-outline-variant/30 space-y-md
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF737878).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Dark Theme toggle
                      // Matches Stitch: flex items-center justify-between, icon text-tertiary
                      _buildSettingsRow(
                        icon: Icons.dark_mode,
                        iconColor: colorScheme.tertiary,
                        label: 'Dark Theme',
                        trailing: Switch(
                          value: false,
                          onChanged: (val) {
                            // MVP: no dark mode yet
                          },
                          activeThumbColor: colorScheme.primary,
                          inactiveTrackColor: colorScheme.surfaceContainerHighest,
                        ),
                        showBorder: false,
                        context: context,
                      ),
                      // Notifications
                      // Matches Stitch: border-t border-outline-variant pt-md, icon text-primary
                      Divider(color: colorScheme.outlineVariant, height: 1),
                      const SizedBox(height: 16),
                      _buildSettingsRow(
                        icon: Icons.notifications,
                        iconColor: colorScheme.primary,
                        label: 'Notifications',
                        trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
                        showBorder: false,
                        context: context,
                      ),
                      // Privacy Settings
                      // Matches Stitch: border-t border-outline-variant pt-md, icon text-secondary
                      Divider(color: colorScheme.outlineVariant, height: 1),
                      const SizedBox(height: 16),
                      _buildSettingsRow(
                        icon: Icons.security,
                        iconColor: colorScheme.secondary,
                        label: 'Privacy Settings',
                        trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
                        showBorder: false,
                        context: context,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Sign Out Button
                // Matches Stitch: w-full bg-error text-on-error py-md rounded-xl font-headline-md
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final authService = ref.read(authServiceProvider);
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.secondaryContainer,
      child: Icon(
        Icons.person,
        size: 64,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }

  /// Matches Stitch info field:
  /// label: text-label-md font-label-md text-secondary ml-1
  /// container: flex items-center gap-3 px-md py-sm bg-surface-container-low rounded-lg
  /// icon: material-symbols-outlined text-outline
  /// input: bg-transparent text-body-md text-on-surface
  Widget _buildInfoField({
    required BuildContext context,
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.outline),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoFieldReadOnly({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.outline),
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
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget trailing,
    required bool showBorder,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        trailing,
      ],
    );
  }
}
