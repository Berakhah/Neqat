import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingProvider = StateNotifierProvider<OnboardingProvider, int>(
    (ref) => OnboardingProvider());

class OnboardingProvider extends StateNotifier<int> {
  OnboardingProvider() : super(0);

  void goToPage(int index) {
    state = index;
  }
}
