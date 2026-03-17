import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/providers/theme_provider.dart';
import '../../domain/profile_model.dart';
import '../providers/profile_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/energy_prefs_picker.dart';

/// The profile screen where users view and edit their profile information,
/// energy preferences, theme mode, and sign out.
///
/// Layout per UI-SPEC "Profile Layout":
/// - Avatar with initials/photo and edit overlay
/// - Display name and email
/// - Display name edit card
/// - Energy preferences picker card
/// - Appearance (theme toggle) card
/// - Sign out button
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// Shows a dialog to edit the display name with a pre-filled TextField.
  Future<void> _editDisplayName(Profile profile) async {
    final controller = TextEditingController(text: profile.displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != profile.displayName) {
      final updated = profile.copyWith(displayName: result);
      await ref.read(profileRepositoryProvider).updateProfile(updated);
      // Invalidate the profile provider to refetch
      final userId = ref.read(authStateProvider).user?.id;
      if (userId != null) {
        ref.invalidate(profileProvider(userId));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile updated'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Updates the energy pattern and saves to Supabase.
  Future<void> _updateEnergyPattern(
    Profile profile,
    EnergyPattern pattern,
  ) async {
    final updated = profile.copyWith(energyPattern: pattern);
    await ref.read(profileRepositoryProvider).updateProfile(updated);
    final userId = ref.read(authStateProvider).user?.id;
    if (userId != null) {
      ref.invalidate(profileProvider(userId));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Profile updated'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Opens the image picker to select a new avatar photo.
  Future<void> _pickAvatar(Profile profile) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final file = File(image.path);
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;

    final avatarUrl =
        await ref.read(profileRepositoryProvider).uploadAvatar(userId, file);
    final updated = profile.copyWith(avatarUrl: avatarUrl);
    await ref.read(profileRepositoryProvider).updateProfile(updated);
    ref.invalidate(profileProvider(userId));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Profile updated'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Shows a confirmation dialog before signing out.
  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out of FocusForge?'),
        content: const Text('You can sign back in anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;
    final currentThemeMode = ref.watch(themeProvider);

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    final profileAsync = ref.watch(profileProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load profile',
                  style: context.textTheme.bodyMedium),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(profileProvider(userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Avatar section
              Center(
                child: AvatarWidget(
                  displayName: profile.displayName,
                  avatarUrl: profile.avatarUrl,
                  onEdit: () => _pickAvatar(profile),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profile.displayName ?? 'No name set',
                style: context.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                authState.user?.email ?? '',
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Display Name card
              Card(
                child: ListTile(
                  title: const Text('Display Name'),
                  subtitle: Text(profile.displayName ?? 'Not set'),
                  trailing: const Icon(Icons.edit_rounded),
                  onTap: () => _editDisplayName(profile),
                ),
              ),
              const SizedBox(height: 16),

              // Energy Preferences card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Energy Preferences',
                        style: context.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      EnergyPrefsPicker(
                        energyPattern: profile.energyPattern,
                        onChanged: (pattern) =>
                            _updateEnergyPattern(profile, pattern),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Appearance card (theme toggle)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('Light'),
                              icon: Icon(Icons.light_mode_rounded),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('Dark'),
                              icon: Icon(Icons.dark_mode_rounded),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('System'),
                              icon: Icon(Icons.settings_brightness_rounded),
                            ),
                          ],
                          selected: {currentThemeMode},
                          onSelectionChanged: (modes) => ref
                              .read(themeProvider.notifier)
                              .setTheme(modes.first),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Sign out button
              AppButton(
                label: 'Sign Out',
                isOutlined: true,
                isDestructive: true,
                onPressed: _confirmSignOut,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
