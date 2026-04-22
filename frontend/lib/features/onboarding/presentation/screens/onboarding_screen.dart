import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:frontend/features/onboarding/presentation/widgets/onboarding_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPageIndex = ref.watch(onboardingProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              ref.read(onboardingProvider.notifier).goToPage(index);
            },
            children: [
              OnboardingPage(
                svg: "onboarding_first",
                title: l10n.onboardingFirstTitle,
                description: l10n.onboardingFirstDescription,
              ),
              OnboardingPage(
                svg: "onboarding_second",
                title: l10n.onboardingSecondTitle,
                description: l10n.onboardingSecondDescription,
              ),
              OnboardingPage(
                svg: "onboarding_third",
                title: l10n.onboardingThirdTitle,
                description: l10n.onboardingThirdDescription,
              ),
            ],
          ),
          Positioned(
            left: -20.0,
            right: 0.0,
            bottom: 150.0,
            child: OnboardingIndicator(currentPageIndex: currentPageIndex),
          ),
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 80.0,
            child: Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 70.0,
                    vertical: 15.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                onPressed: () {
                  if (currentPageIndex < 2) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }

                  if (currentPageIndex == 2) {
                    context.push('/login');
                  }
                },
                child: Text(
                  currentPageIndex < 2 ? l10n.nextButton : l10n.getStartedButton,
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.svg,
    required this.title,
    required this.description,
  });
  final String svg;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.4,
          child: SvgPicture.asset('images/$svg.svg'),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}