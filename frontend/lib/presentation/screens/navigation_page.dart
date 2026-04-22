import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/navigation_provider.dart';
import 'package:frontend/app/providers/theme_notifier.dart';
import 'package:frontend/features/review/presentation/pages/review_screen.dart';
import 'package:frontend/features/review/presentation/providers/product_provider.dart';
import 'package:frontend/features/settings/presentation/pages/settings_screen.dart';
import 'package:frontend/presentation/screens/home_screen.dart';
import 'package:frontend/presentation/screens/search_news.dart';
import 'package:rive_animated_icon/rive_animated_icon.dart';

class BottomNavigationPage extends ConsumerStatefulWidget {
  const BottomNavigationPage({super.key});

  @override
  ConsumerState<BottomNavigationPage> createState() =>
      _BottomNavigationPageState();
}

class _BottomNavigationPageState extends ConsumerState<BottomNavigationPage> {
  final int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();

  List<RiveAnimatedIcon> getNavigationItems(int currentIndex, bool isDark) {
    print("Is dark $isDark");
    return [
      RiveAnimatedIcon(
        height: 36,
        width: 36,
        riveIcon: RiveIcon.home2,
        color: isDark ? Colors.white : Colors.black,
        loopAnimation: true,
        strokeWidth: 4,
        onTap: () {
          ref.read(navigationProvider.notifier).goToPage(0);
        },
      ),
      RiveAnimatedIcon(
        height: 36,
        width: 36,
        riveIcon: RiveIcon.search,
        color: isDark ? Colors.white : Colors.black,
        loopAnimation: true,
        strokeWidth: 4,
        onTap: () {
          ref.read(navigationProvider.notifier).goToPage(1);
        },
      ),
      RiveAnimatedIcon(
        height: 36,
        width: 36,
        riveIcon: RiveIcon.message,
        color: isDark ? Colors.white : Colors.black,
        loopAnimation: true,
        strokeWidth: 4,
        onTap: () {
          ref.read(navigationProvider.notifier).goToPage(2);
        },
      ),
      RiveAnimatedIcon(
        height: 36,
        width: 36,
        riveIcon: RiveIcon.settings,
        color: isDark ? Colors.white : Colors.black,
        loopAnimation: true,
        strokeWidth: 4,
        onTap: () {
          ref.read(navigationProvider.notifier).goToPage(3);
        },
      ),
      // RiveAnimatedIcon(
      //   height: 36,
      //   width: 36,
      //   riveIcon: RiveIcon.like,
      //   color: isDark ? Colors.white : Colors.black,
      //   loopAnimation: true,
      //   strokeWidth: 4,
      //   onTap: () {
      //     ref.read(navigationProvider.notifier).goToPage(4);
      //   },
      // ),
    ];
  }

  Future<void> _handleRefresh() async {
    if (_currentIndex == 0) {
      await _homeScreenKey.currentState?.refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final productState = ref.watch(productControllerProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    print(currentIndex);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: IndexedStack(
          index: currentIndex,
          children: [
            HomeScreen(key: _homeScreenKey),
            SearchNews(news: 'Top'),
            const ReviewScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 27, vertical: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white12 : Colors.black12,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                getNavigationItems(currentIndex, isDark).asMap().entries.map((
              entry,
            ) {
              final index = entry.key;
              final navigationItem = entry.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 2,
                    width: 30,
                    color: currentIndex == index
                        ? isDark
                            ? Colors.white
                            : Colors.black
                        : Colors.transparent,
                    margin: const EdgeInsets.only(bottom: 4),
                  ),
                  navigationItem,
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
