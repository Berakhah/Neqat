import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/providers/scanner_providers.dart';
import 'package:frontend/domain/barcode_logic.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/presentation/screens/manual_entry_screen.dart';
import 'package:frontend/presentation/screens/product_details_screen.dart';
import 'package:frontend/features/review/domain/entities/product.dart';

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startScanning());
    }
  }

  Future<Product?> _fetchProduct(String barcode) async {
    try {
      if (barcode.isNotEmpty) {
        return Product(
          id: barcode, // Use barcode as the ID
          productName: 'Sample Product',
          genericName: 'Sample Generic Name',
          brands: 'SampleBrand',
          quantity: '100g',
          imageFrontUrl: null,
          imageFrontSmallUrl: null,
          categories: 'Groceries',
          ingredientsText: 'Sugar, Flour, Water',
          nutriscoreGrade: 'B',
          ecoscoreGrade: 'A',
          nutriments: null,
          labelsTags: ['organic'],
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _startScanning() async {
    ref.read(scanLoadingProvider.notifier).state = true;
    final barcodeLogic = ref.read(barcodeLogicProvider);
    final result = await barcodeLogic.scanBarcode();
    final l10n = AppLocalizations.of(context)!;

    if (result.isNotEmpty && !result.contains('Error')) {
      final product = await _fetchProduct(result);

      if (mounted) {
        if (product != null) {
          context.go('/productDetails', extra: product);
        } else {
          BarcodeLogic.showResultDialog(
            context: context,
            title: l10n.errorTitle,
            message: 'Product not found for barcode: $result',
          );
        }
      }
    } else if (result.contains('Error') && mounted) {
      BarcodeLogic.showResultDialog(
        context: context,
        title: l10n.errorTitle,
        message: result,
      );
    }
    if (mounted) {
      ref.read(scanLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orientation = MediaQuery.of(context).orientation;
    final isFlashOn = ref.watch(flashStateProvider);
    final isLoading = ref.watch(scanLoadingProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (kIsWeb)
            Center(
              child: Text(
                l10n.webBarcodeUnsupported,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            )
          else
            Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 30.0),
                    color: theme.colorScheme.surface,
                    child: Center(
                      child: isLoading
                          ? Container(color: theme.colorScheme.surface)
                          : Image.asset(
                              'assets/MoyaPlaceholderTransparent.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  l10n.imageLoadFailed,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          if (!kIsWeb)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 400,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.onSurface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!kIsWeb)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  l10n.pointCameraAtBarcode,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          if (!kIsWeb && isLoading)
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: theme.appBarTheme.backgroundColor,
              child: SafeArea(
                minimum: const EdgeInsets.only(top: 4.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 2.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: theme.appBarTheme.iconTheme?.color,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        l10n.scanBarcodeTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!kIsWeb)
                        IconButton(
                          icon: Icon(
                            isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: theme.appBarTheme.iconTheme?.color,
                          ),
                          onPressed: () {
                            ref.read(flashStateProvider.notifier).state = !isFlashOn;
                            if (isLoading) _startScanning();
                          },
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.all(12.0),
              child: orientation == Orientation.landscape
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!kIsWeb && !isLoading)
                          Padding(
                            padding: const EdgeInsets.only(left: 40.0),
                            child: ElevatedButton.icon(
                              onPressed: _startScanning,
                              icon: const Icon(Icons.camera_alt),
                              label: Text(l10n.startScanningButton),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              constraints: const BoxConstraints(minWidth: 180),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 8.0,
                                ),
                                child: Text(
                                  kIsWeb
                                      ? l10n.manualEntryWebPrompt
                                      : l10n.enterCodeManuallyPrompt,
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 40.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  context.go('/manualEntry');
                                },
                                child: Text(
                                  l10n.enterCodeButton,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!kIsWeb && !isLoading)
                          ElevatedButton.icon(
                            onPressed: _startScanning,
                            icon: const Icon(Icons.camera_alt),
                            label: Text(l10n.startScanningButton),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (!kIsWeb)
                          Text(
                            l10n.manualEntryNonWebPrompt,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          )
                        else
                          Text(
                            l10n.manualEntryWebPrompt,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.go('/manualEntry');
                          },
                          child: Text(
                            l10n.enterCodeButton,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}