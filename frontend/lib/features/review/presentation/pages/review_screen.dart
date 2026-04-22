import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/theme_notifier.dart';
import 'package:frontend/features/review/presentation/providers/product_provider.dart';
import 'package:frontend/features/review/presentation/widgets/shimmerList.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/l10n/app_localizations.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _onSubmit() {
    final query = _searchController.text.trim();
    ref.read(productControllerProvider.notifier).getProducts(query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productControllerProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 130,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 40),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(50.0),
                bottomRight: Radius.circular(50.0),
              ),
            ),
            child: Text(
              l10n.productsTitle,
              style: TextStyle(
                color: theme.textTheme.headlineSmall?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 85,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _onSubmit(),
                decoration: InputDecoration(
                  hintText: l10n.searchProductsHint,
                  filled: true,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  fillColor: isDark ? Colors.white12 : Colors.black12,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  suffixIcon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 160),
            child: productState.when(
              loading: () => ShimmerList(isDark: isDark),
              error: (err, _) => Center(child: Text('${l10n.errorPrefix} $err')),
              data: (products) => products.isEmpty
                  ? Center(child: Text(l10n.noProductsFound))
                  : RefreshIndicator(
                      onRefresh: () async {
                        final query = _searchController.text.trim();
                        await ref
                            .read(productControllerProvider.notifier)
                            .getProducts(query);
                      },
                      child: ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ListTile(
                            leading: product.imageFrontUrl != null
                                ? Image.network(
                                    product.imageFrontUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image_not_supported),
                            title: Text(product.productName ?? l10n.noName),
                            subtitle: Text(product.brands ?? l10n.noBrandInfo),
                            onTap: () {
                              context.push(
                                '/productDetails',
                                extra: product,
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: _ExpandableFAB(isDark: isDark),
    );
  }
}

class _ExpandableFAB extends StatefulWidget {
  final bool isDark;

  const _ExpandableFAB({required this.isDark});

  @override
  State<_ExpandableFAB> createState() => _ExpandableFABState();
}

class _ExpandableFABState extends State<_ExpandableFAB>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            right: _expanded ? 60 : 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _expanded ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: FloatingActionButton.small(
                heroTag: 'btn1',
                onPressed: () {
                  context.go('/manualEntry');
                },
                child: const Icon(Icons.keyboard),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            right: _expanded ? 120 : 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _expanded ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: FloatingActionButton.small(
                heroTag: 'btn2',
                onPressed: () {
                  context.go('/scanner');
                },
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
          FloatingActionButton(
            backgroundColor: widget.isDark ? Colors.white12 : Colors.black12,
            heroTag: 'main',
            onPressed: () {
              setState(() => _expanded = !_expanded);
            },
            child: AnimatedRotation(
              turns: _expanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.qr_code_scanner,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}