import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/app/providers/theme_notifier.dart';
import 'package:frontend/app/routes.dart';
import 'package:frontend/app/themes.dart';
import 'package:frontend/features/auth/data/datasources/auth_api_service.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Add this import

// Define providers for auth services
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService();
});

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  final authApiService = ref.watch(authApiServiceProvider);
  return AuthRepositoryImpl(authApiService: authApiService);
});

// Locale provider to manage the app's language
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    state = Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    state = locale;
  }
}

void main() async {
  await dotenv.load(fileName: "api.env");
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Neqat',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}