import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../app/providers/service_providers.dart';
import '../../../app/theme/accessibility_palettes.dart';
import '../../../app/theme/color_tokens.dart';

/// UF5: Settings Screen - Accessibility and preferences
///
/// Features:
/// - Accessibility section:
///   - Color vision mode dropdown (5 options: Default Night, Deuteranopia, Protanopia, Tritanopia, Monochrome)
///   - TTS toggle
///   - TTS rate slider (slow/normal)
///   - Preview button to test current settings
/// - Other settings (notifications, units, etc.)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AccessibilityMode _selectedMode = AccessibilityMode.defaultNight;
  bool _ttsEnabled = false;
  double _ttsRate = 0.5; // 0.0 = slow, 1.0 = normal

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceScreen());
  }

  Future<void> _announceScreen() async {
    final tts = ref.read(ttsServiceProvider);
    await tts.speakScreenSummary('Settings');
  }

  Future<void> _loadSettings() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final enabled = await prefs.isTtsEnabled();
    final rate = await prefs.getTtsRate();

    if (mounted) {
      setState(() {
        _ttsEnabled = enabled;
        _ttsRate = rate;
      });
    }
  }

  Future<void> _updateAccessibilityMode(AccessibilityMode mode) async {
    setState(() {
      _selectedMode = mode;
    });

    // TODO: Update provider and persist to database
    // ref.read(accessibilitySettingsProvider.notifier).setMode(mode);
    // await ref.read(preferencesRepositoryProvider).setAccessibilityMode(mode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme changed to ${_getModeName(mode)}'),
          backgroundColor: ColorTokens.success,
        ),
      );
    }
  }

  Future<void> _toggleTts(bool enabled) async {
    setState(() {
      _ttsEnabled = enabled;
    });

    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setTtsEnabled(enabled);

    final tts = ref.read(ttsServiceProvider);
    if (enabled) {
      await tts.enable();
      await tts.setRate(_ttsRate);
      await tts.speak('Text to speech enabled');
    } else {
      await tts.disable();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ttsEnabled ? 'Text-to-Speech enabled' : 'Text-to-Speech disabled'),
          backgroundColor: ColorTokens.success,
        ),
      );
    }
  }

  Future<void> _updateTtsRate(double rate) async {
    setState(() {
      _ttsRate = rate;
    });

    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setTtsRate(rate);

    final tts = ref.read(ttsServiceProvider);
    await tts.setRate(rate);
  }

  Future<void> _previewSettings() async {
    final tts = ref.read(ttsServiceProvider);
    final speedDesc = _ttsRate < 0.4 ? 'slow' : _ttsRate > 0.7 ? 'fast' : 'normal';
    await tts.speak(
      'Settings preview. Text to speech is enabled at $speedDesc speed. This is how navigation announcements will sound.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playing preview'),
          backgroundColor: ColorTokens.accent,
        ),
      );
    }
  }

  String _getModeName(AccessibilityMode mode) {
    switch (mode) {
      case AccessibilityMode.defaultNight:
        return 'Default Night';
      case AccessibilityMode.deuteranopia:
        return 'Deuteranopia (Red-Green)';
      case AccessibilityMode.protanopia:
        return 'Protanopia (Red-Green Variant)';
      case AccessibilityMode.tritanopia:
        return 'Tritanopia (Blue-Yellow)';
      case AccessibilityMode.monochrome:
        return 'Monochrome (High Contrast)';
    }
  }

  String _getModeDescription(AccessibilityMode mode) {
    switch (mode) {
      case AccessibilityMode.defaultNight:
        return 'Dark theme optimized for night shift workers';
      case AccessibilityMode.deuteranopia:
        return 'Adjusted colors for deuteranopia (most common color blindness)';
      case AccessibilityMode.protanopia:
        return 'Adjusted colors for protanopia (red-green color blindness)';
      case AccessibilityMode.tritanopia:
        return 'Adjusted colors for tritanopia (blue-yellow color blindness)';
      case AccessibilityMode.monochrome:
        return 'High contrast black/white/gray with shapes for clarity';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: ColorTokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorTokens.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left, color: ColorTokens.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accessibility section
            _SectionHeader(
              icon: TablerIcons.eye,
              title: 'Accessibility',
              subtitle: 'Visual and audio accessibility options',
            ),

            const SizedBox(height: 12),

            // Color vision mode
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorTokens.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorTokens.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(TablerIcons.palette, color: ColorTokens.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Color Vision Mode',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: ColorTokens.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getModeDescription(_selectedMode),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: ColorTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Mode selector
                  ...AccessibilityMode.values.map((mode) {
                    final isSelected = mode == _selectedMode;
                    return _ModeOption(
                      mode: mode,
                      name: _getModeName(mode),
                      isSelected: isSelected,
                      onTap: () => _updateAccessibilityMode(mode),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TTS settings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorTokens.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TTS toggle
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorTokens.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(TablerIcons.volume, color: ColorTokens.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Text-to-Speech',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: ColorTokens.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Announces screen changes and workout milestones',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: ColorTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _ttsEnabled,
                        activeThumbColor: ColorTokens.accent,
                        onChanged: _toggleTts,
                      ),
                    ],
                  ),

                  if (_ttsEnabled) ...[
                    const SizedBox(height: 16),
                    const Divider(color: ColorTokens.border, height: 1),
                    const SizedBox(height: 16),

                    // TTS rate slider
                    Row(
                      children: [
                        const Icon(TablerIcons.gauge, color: ColorTokens.accent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Speech Rate',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: ColorTokens.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Slow',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: ColorTokens.textSecondary,
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _ttsRate,
                                      min: 0.0,
                                      max: 1.0,
                                      divisions: 10,
                                      activeColor: ColorTokens.accent,
                                      inactiveColor: ColorTokens.border,
                                      onChanged: _updateTtsRate,
                                    ),
                                  ),
                                  Text(
                                    'Normal',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: ColorTokens.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Preview button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _previewSettings,
                        icon: const Icon(TablerIcons.player_play, size: 18),
                        label: const Text('Preview Voice'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: ColorTokens.accent,
                          side: const BorderSide(color: ColorTokens.accent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // General section
            _SectionHeader(
              icon: TablerIcons.settings,
              title: 'General',
              subtitle: 'App preferences and settings',
            ),

            const SizedBox(height: 12),

            // Notifications
            Consumer(
              builder: (context, ref, child) {
                return FutureBuilder<bool?>(
                  future: ref.read(preferencesRepositoryProvider).getBool('notifications_enabled'),
                  builder: (context, snapshot) {
                    final enabled = snapshot.data ?? true;
                    return _SettingTile(
                      icon: TablerIcons.bell,
                      title: 'Notifications',
                      subtitle: 'Workout reminders',
                      trailing: Switch(
                        value: enabled,
                        activeThumbColor: ColorTokens.accent,
                        onChanged: (value) async {
                          await ref.read(preferencesRepositoryProvider).setBool('notifications_enabled', value);
                        },
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Data section
            _SectionHeader(
              icon: TablerIcons.database,
              title: 'Data',
              subtitle: 'Backup and sync settings',
            ),

            const SizedBox(height: 12),

            // Sync status (placeholder)
            _SettingTile(
              icon: TablerIcons.cloud,
              title: 'Cloud Sync',
              subtitle: 'Last synced: 2 hours ago',
              trailing: const Icon(TablerIcons.chevron_right, color: ColorTokens.textSecondary),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Syncing...')),
                );
              },
            ),

            const SizedBox(height: 24),

            // Account section
            _SectionHeader(
              icon: TablerIcons.user,
              title: 'Account',
              subtitle: 'User account and authentication',
            ),

            const SizedBox(height: 12),

            // Email display
            Consumer(
              builder: (context, ref, child) {
                final user = ref.watch(currentUserProvider);
                return _SettingTile(
                  icon: TablerIcons.mail,
                  title: 'Email',
                  subtitle: user?.email ?? 'Not signed in',
                  trailing: const SizedBox.shrink(),
                );
              },
            ),

            const SizedBox(height: 8),

            // Logout button
            Consumer(
              builder: (context, ref, child) {
                return _SettingTile(
                  icon: TablerIcons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  trailing: const Icon(TablerIcons.chevron_right, color: ColorTokens.error),
                  onTap: () async {
                    // Show confirmation dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: ColorTokens.surface,
                        title: const Text('Logout', style: TextStyle(color: ColorTokens.textPrimary)),
                        content: const Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(color: ColorTokens.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel', style: TextStyle(color: ColorTokens.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout', style: TextStyle(color: ColorTokens.error)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      // Clear auth flag
                      final prefs = ref.read(preferencesRepositoryProvider);
                      await prefs.setBool('was_authenticated', false);

                      // Sign out
                      final auth = ref.read(firebaseAuthProvider);
                      await auth.signOut();

                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // About section
            _SectionHeader(
              icon: TablerIcons.info_circle,
              title: 'About',
              subtitle: 'App information',
            ),

            const SizedBox(height: 12),

            // Version
            _SettingTile(
              icon: TablerIcons.code,
              title: 'Version',
              subtitle: '1.0.0',
              trailing: const SizedBox.shrink(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: ColorTokens.accent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: ColorTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ColorTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mode option widget
class _ModeOption extends StatelessWidget {
  final AccessibilityMode mode;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.mode,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? ColorTokens.accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? ColorTokens.accent : ColorTokens.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Color preview (shows theme accent color)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getPreviewColor(mode),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? ColorTokens.accent : ColorTokens.border,
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? ColorTokens.accent : ColorTokens.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(TablerIcons.check, color: ColorTokens.accent, size: 20),
          ],
        ),
      ),
    );
  }

  Color _getPreviewColor(AccessibilityMode mode) {
    // Return the accent color for each mode
    final palette = AccessibilityPalettes.getPalette(mode);
    return palette.accent;
  }
}

/// Setting tile widget
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorTokens.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorTokens.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: ColorTokens.accent, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: ColorTokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: ColorTokens.textSecondary,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}
