import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/theme_notifier.dart';
import 'package:frontend/app/themes.dart';
import 'package:frontend/features/settings/presentation/widgets/edit_profile_sheet.dart';
import 'package:frontend/features/settings/presentation/widgets/list_tile.dart';
import 'package:frontend/features/settings/presentation/widgets/settings_option.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/app/main.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/providers/user_provider.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/features/settings/presentation/providers/user_profile_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final userProfileState = ref.watch(userProfileProvider);
    final user = userProfileState.user;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20.0,
                          backgroundColor: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(1.5),
                              child: CircleAvatar(
                                radius: 19.0,
                                backgroundImage: user?.profile_photo != null && user!.profile_photo!.isNotEmpty
                                    ? CachedNetworkImageProvider(user.profile_photo!) as ImageProvider
                                    : null,
                                child: user?.profile_photo == null || user!.profile_photo!.isEmpty
                                    ? const Icon(Icons.person, size: 20)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.first_name != null && user!.first_name.isNotEmpty
                                ? l10n.userGreeting(user.first_name)
                                : "Hello",
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
                      padding: EdgeInsets.symmetric(
                        vertical: 2.0,
                        horizontal: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: InkWell(
                        onTap: () {
                          context.push('/profile');
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 13.0,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            SizedBox(width: 4.0),
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
                SizedBox(height: 30.0),
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
                  ],
                ),
                SizedBox(height: 40.0),
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
                      trailingWidget: Icon(Icons.chevron_right),
                    ),
                    const SizedBox(height: 20.0),
                    ListTiles(
                      isDark: isDark,
                      leadingIcon: Icons.change_circle_outlined,
                      leadingText: l10n.changePasswordOption,
                      trailingWidget: Icon(Icons.chevron_right),
                    ),
                    const SizedBox(height: 20.0),
                    ListTiles(
                      isDark: isDark,
                      leadingIcon: Icons.logout_outlined,
                      leadingText: l10n.logOutOption,
                      trailingWidget: Container(),
                      onTap: () async {
                        final authRepository = ref.read(authRepositoryProvider);
                        final success = await authRepository.logout();

                        if (success) {
                          ref.read(userProvider.notifier).clearUserData();
                          ref.read(authProvider.notifier).clearToken();

                          if (context.mounted) {
                            context.go('/login');
                          }
                        } else {
                          print("Logout failed");
                        }
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
}
