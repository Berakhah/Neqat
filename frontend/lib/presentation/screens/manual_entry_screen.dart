import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/providers/scanner_providers.dart';
import 'package:frontend/l10n/app_localizations.dart';

class ManualEntryPage extends ConsumerStatefulWidget {
  const ManualEntryPage({super.key});

  @override
  ConsumerState<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends ConsumerState<ManualEntryPage> {
  final TextEditingController _controller = TextEditingController();

  void _submitCode() async {
    final l10n = AppLocalizations.of(context)!;
    if (_controller.text.length == 13) {
      ref.read(scanLoadingProvider.notifier).state = true;
      // Simulate a successful submission (placeholder for actual product fetch)
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      if (mounted) {
        ref.read(scanLoadingProvider.notifier).state = false;
        context.go('/productDetails'); // Placeholder navigation
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n.errorTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          content: Text(
            l10n.codeLengthError,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                l10n.okButton,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(scanLoadingProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: theme.appBarTheme.backgroundColor,
                child: SafeArea(
                  child: Container(
                    color: theme.appBarTheme.backgroundColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: theme.appBarTheme.iconTheme?.color,
                          ),
                          onPressed: () => context.go('/reviews'),
                        ),
                        Text(
                          l10n.enterCodeManuallyTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.appBarTheme.titleTextStyle?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(
                color: theme.dividerTheme.color,
                thickness: theme.dividerTheme.thickness,
                height: theme.dividerTheme.space,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxContentWidth = constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
                    return SingleChildScrollView(
                      child: Center(
                        child: Container(
                          width: maxContentWidth,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 16),
                              TextField(
                                controller: _controller,
                                keyboardType: TextInputType.number,
                                maxLength: 13,
                                decoration: InputDecoration(
                                  labelText: l10n.enterBarcodeLabel,
                                  labelStyle: theme.inputDecorationTheme.labelStyle,
                                  border: theme.inputDecorationTheme.border,
                                  enabledBorder: theme.inputDecorationTheme.enabledBorder,
                                  focusedBorder: theme.inputDecorationTheme.focusedBorder,
                                ),
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: isLoading ? null : _submitCode,
                                style: theme.elevatedButtonTheme.style,
                                child: Text(
                                  l10n.submitButton,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}