import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/main.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/providers/theme_notifier.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:frontend/app/providers/user_provider.dart';
import 'package:frontend/app/themes.dart';
import 'package:frontend/features/settings/presentation/widgets/edit_profile_sheet.dart';
import 'package:frontend/features/settings/presentation/widgets/list_tile.dart';
import 'package:frontend/features/settings/presentation/widgets/settings_option.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/features/auth/data/services/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;
  String _biometricType = '';
  bool _isBiometricProcessing = false;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    // Check if biometric authentication is available
    _checkBiometrics();
  }

  // Check biometric availability
  Future<void> _checkBiometrics() async {
    try {
      final biometricService = ref.read(biometricServiceProvider);

      final isAvailable = await biometricService.isBiometricAvailable();
      final isEnabled = await biometricService.isBiometricEnabled();
      final biometricType = await biometricService.getBiometricTypeString();

      if (mounted) {
        setState(() {
          _biometricsAvailable = isAvailable;
          _biometricsEnabled = isEnabled;
          _biometricType = biometricType;
        });
      }
    } catch (e) {
      // Silently fail - biometrics might not be supported
      _logger.e('Failed to check biometrics: $e');
    }
  }

  // Toggle biometric authentication
  Future<void> _toggleBiometricAuth(bool value) async {
    if (_isBiometricProcessing) return;

    setState(() {
      _isBiometricProcessing = true;
    });

    try {
      final biometricService = ref.read(biometricServiceProvider);

      if (value) {
        // Get current user email
        final email = ref.read(authProvider).user?['email'] as String?;

        if (email == null) {
          _showSnackBar('User profile not available. Please log in again.');
          setState(() {
            _isBiometricProcessing = false;
          });
          return;
        }

        // Enable biometric authentication
        final success = await biometricService.enableBiometric(email);

        if (success) {
          // Save current credentials for biometric login
          final secureStorage = const FlutterSecureStorage();
          await secureStorage.write(key: 'last_email', value: email);

          _showSnackBar('Biometric login enabled successfully');

          setState(() {
            _biometricsEnabled = true;
            _isBiometricProcessing = false;
          });
        } else {
          _showSnackBar('Failed to enable biometric login');
          setState(() {
            _isBiometricProcessing = false;
          });
        }
      } else {
        // Disable biometric authentication
        await biometricService.disableBiometric();

        _showSnackBar('Biometric login disabled');

        setState(() {
          _biometricsEnabled = false;
          _isBiometricProcessing = false;
        });
      }
    } catch (e) {
      _logger.e('Error toggling biometric auth: $e');
      _showSnackBar('Error: $e');
      setState(() {
        _isBiometricProcessing = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showEditProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const EditProfileSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final userState = ref.watch(userProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Consumer(
              builder: (context, ref, _) {
                return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(radius: 20.0),
                        const SizedBox(width: 10.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.userGreeting("Alex"),
                              style: getInterTextStyle(
                                isDark: isDark,
                                fontSize: 18.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2.0,
                        horizontal: 8.0,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: InkWell(
                        onTap: () {
                          _showEditProfileBottomSheet(context);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 13.0,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              l10n.editButton,
                              style: getInterTextStyle(
                                isDark: isDark,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30.0),
                Text(
                  l10n.preferencesTitle,
                  style: getInterTextStyle(isDark: isDark, fontSize: 20.0),
                ),
                SettingsOption(
                  isDark: isDark,
                  listTiles: [
                    ListTiles(
                      isDark: isDark,
                      leadingIcon: Icons.newspaper,
                      leadingText: l10n.globalNewsOption,
                      trailingWidget: Switch(
                        value: false,
                        onChanged: (value) {},
                        activeColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    ListTiles(
                      isDark: isDark,
                      leadingIcon: Icons.notifications_none_outlined,
                      leadingText: l10n.notificationOption,
                      trailingWidget: Switch(
                        value: false,
                        onChanged: (value) {},
                        activeColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    ListTiles(
                      isDark: isDark,
                      leadingIcon: Icons.dark_mode_outlined,
                      leadingText: l10n.darkModeOption,
                      trailingWidget: Switch(
                        value: isDark,
                        onChanged: (value) {
                          ref
                              .read(themeNotifierProvider.notifier)
                              .toggleTheme(value);
                        },
                        activeColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    ListTiles(
                      isDark: isDark,
                      leadingIcon: Icons.language_rounded,
                      leadingText: l10n.languageToggleLabel,
                      trailingWidget: Switch(
                        value: locale.languageCode == 'am',
                        onChanged: (value) {
                          ref
                              .read(localeProvider.notifier)
                              .setLocale(
                                value ? const Locale('am') : const Locale('en'),
                              );
                        },
                        activeColor: Colors.blue,
                      ),
                    ),
                    // Add biometric authentication option if available
                    if (_biometricsAvailable) ...[
                      const SizedBox(height: 20.0),
                      ListTiles(
                        isDark: isDark,
                        leadingIcon:
                            _biometricType.toLowerCase().contains('face')
                                ? Icons.face
                                : Icons.fingerprint,
                        leadingText: 'Biometric Login ($_biometricType)',
                        trailingWidget:
                            _isBiometricProcessing
                                ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue,
                                  ),
                                )
                                : Switch(
                                  value: _biometricsEnabled,
                                  onChanged: _toggleBiometricAuth,
                                  activeColor: Colors.blue,
                                ),
                      ),
                      const SizedBox(height: 20.0),
                      GestureDetector(
                        onTap: () {
                          context.go('/biometric-test');
                        },
                        child: ListTiles(
                          isDark: isDark,
                          leadingIcon: Icons.security,
                          leadingText: 'Test Biometrics',
                          trailingWidget: const Icon(Icons.chevron_right),
                        ),
                      ),
                    ],
                        // Insert Admin Panel option for admin users
                        if (userState.isAdmin) ...[
                          const SizedBox(height: 20.0),
                          GestureDetector(
                            onTap: () {
                              context.go('/admin');
                            },
                            child: ListTiles(
                              isDark: isDark,
                              leadingIcon: Icons.admin_panel_settings,
                              leadingText: 'Admin Panel',
                              trailingWidget: const Icon(Icons.chevron_right),
                            ),
                          ),
                        ],
                  ],
                ),
                const SizedBox(height: 40.0),
                Text(
                  l10n.supportTitle,
                  style: getInterTextStyle(isDark: isDark, fontSize: 20.0),
                ),
                SettingsOption(
                  isDark: isDark,
                  listTiles: [
                    ListTiles(
                      isDark: isDark,
                      leadingIcon: Icons.help_outline_outlined,
                      leadingText: l10n.helpCenterOption,
                      trailingWidget: const Icon(Icons.chevron_right),
                    ),
                    const SizedBox(height: 20.0),
                    ListTiles(
                      isDark: isDark,
                      leadingIcon: Icons.change_circle_outlined,
                      leadingText: l10n.changePasswordOption,
                      trailingWidget: const Icon(Icons.chevron_right),
                    ),
                    const SizedBox(height: 20.0),
                    GestureDetector(
                      onTap: () {
                        context.go('/user/activity-log');
                      },
                      child: ListTiles(
                        isDark: isDark,
                        leadingIcon: Icons.history,
                        leadingText: 'My Activity Log',
                        trailingWidget: const Icon(Icons.chevron_right),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    GestureDetector(
                      onTap: () async {
                        final authRepository = ref.read(authRepositoryProvider);
                        await authRepository.logout();
                        ref.read(authProvider.notifier).clear();
                        ref.read(userProvider.notifier).clearUserData();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      child: ListTiles(
                        isDark: isDark,
                        leadingIcon: Icons.logout_outlined,
                        leadingText: l10n.logOutOption,
                        trailingWidget: Container(),
                      ),
                    ),
                  ],
                ),
              ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

}
