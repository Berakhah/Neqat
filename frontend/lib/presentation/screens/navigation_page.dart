import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/navigation_provider.dart';
import 'package:frontend/app/providers/theme_notifier.dart';
import 'package:frontend/features/review/presentation/pages/review_screen.dart';
import 'package:frontend/features/review/presentation/providers/product_provider.dart';
import 'package:frontend/features/settings/presentation/pages/settings_screen.dart';
import 'package:frontend/presentation/screens/bookmarks_screen.dart';
import 'package:frontend/presentation/screens/home_screen.dart';
import 'package:frontend/presentation/screens/search_news.dart';
import 'package:rive_animated_icon/rive_animated_icon.dart';

class BottomNavigationPage extends ConsumerStatefulWidget {
  const BottomNavigationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<BottomNavigationPage> createState() =>
      _BottomNavigationPageState();
}

class _BottomNavigationPageState extends ConsumerState<BottomNavigationPage> {
  int _currentIndex = 0;
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
    final _currentIndex = ref.watch(navigationProvider);
    final productState = ref.watch(productControllerProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    print(_currentIndex);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(key: _homeScreenKey),
            SearchNews(news: 'Top'),
            const ReviewScreen(),
            const SettingsScreen(),
            const BookmarkScreen(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor:
            Theme.of(context)
                .colorScheme
                .primary, // Changed from Colors.pinkAccent to theme primary color
        onPressed: () {
          // TODO: Implement the action for the central add button
          print("Add button pressed!");
        },
        child: const Icon(Icons.add, color: Colors.white, size: 40),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color:
            isDark ? Colors.white12 : Colors.black12, // Match the theme color
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildNavItem(Icons.home, 'Home', 0, _currentIndex, isDark),
              _buildNavItem(Icons.search, 'Search', 1, _currentIndex, isDark),
              const SizedBox(width: 48), // Placeholder for the FAB notch
              _buildNavItem(Icons.history, 'History', 2, _currentIndex, isDark),
              _buildNavItem(
                Icons.collections_bookmark_outlined,
                'Favorites',
                4,
                _currentIndex,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    int currentIndex,
    bool isDark,
  ) {
    final isSelected = currentIndex == index;
    final color =
        isDark
            ? (isSelected ? Colors.white : Colors.white54)
            : (isSelected ? Colors.black : Colors.black54);

    return InkWell(
      onTap: () {
        ref.read(navigationProvider.notifier).goToPage(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 2,
            width: 30,
            color: isSelected ? color : Colors.transparent,
            margin: const EdgeInsets.only(bottom: 4),
          ),
          Icon(icon, color: color, size: 24),
        ],
      ),
    );
  }
}
