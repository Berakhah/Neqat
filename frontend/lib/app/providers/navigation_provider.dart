import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationProvider = StateNotifierProvider<NavigationProvider, int>(
  (ref) => NavigationProvider(),
);

class NavigationProvider extends StateNotifier<int> {
  NavigationProvider() : super(0);

  void goToPage(int index) {
    state = index;
  }
}
