import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/app/providers/auth_provider.dart';
import 'package:frontend/app/providers/theme_notifier.dart';
import 'package:frontend/app/routes.dart';
import 'package:frontend/app/themes.dart';
import 'package:frontend/core/presentation/session_timeout_handler.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/security_gate.dart';

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
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "api.env");
  runApp(
    SecurityGate(
      child: ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});
  
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Check authentication status on app start
    Future.microtask(() async {
      await ref.read(authProvider.notifier).checkAuthStatus();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeProvider);

    return SessionTimeoutWrapper(
      child: MaterialApp.router(
        title: 'Neqat',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        routerConfig: appRouter,
        locale: locale, // Set the app's locale
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}