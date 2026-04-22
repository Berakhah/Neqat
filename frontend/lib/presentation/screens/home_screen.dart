import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/app/providers/navigation_provider.dart';
import 'package:frontend/app/providers/theme_notifier.dart';
import 'package:frontend/application/data_sources/category_list.dart';
import 'package:frontend/application/data_sources/news.dart';
import 'package:frontend/application/data_sources/slider_data.dart';
import 'package:frontend/domain/entities/article_model.dart';
import 'package:frontend/domain/entities/category_model.dart';
import 'package:frontend/domain/entities/slider_model.dart';
import 'package:frontend/presentation/screens/all_news.dart';
import 'package:frontend/presentation/screens/article_view.dart';
import 'package:frontend/presentation/screens/category_news.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:frontend/presentation/widgets/blog_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:frontend/core/presentation/widgets/proxied_network_image.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  List<CategoryModel> categories = [];
  List<SliderModel> sliders = [];
  List<ArticleModel> articles = [];
  bool _newsLoading = true;
  String? _errorMessage;
  int _activeIndex = 0;

  @override
  void initState() {
    _initializeData();
    super.initState();
  }

  Future<void> _initializeData() async {
    setState(() {
      _newsLoading = true;
      _errorMessage = null;
    });
    categories = getCategories();
    await Future.wait([_loadSliders(), _loadNews()]);
    await Future.delayed(
      const Duration(seconds: 2),
    ); // Ensure shimmer visibility
    if (mounted) {
      setState(() {
        _newsLoading = false;
        if (articles.isEmpty) {
          _errorMessage = 'Failed to load news. Please try again.';
        }
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _newsLoading = true;
      _errorMessage = null;
    });
    await Future.wait([_loadSliders(), _loadNews()]);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _newsLoading = false;
        if (articles.isEmpty) {
          _errorMessage = 'Failed to load news. Please try again.';
        }
      });
    }
  }

  Future<void> _loadSliders() async {
    final slider = Sliders();
    await slider.getSliders(ref);
    sliders = slider.sliders;
  }

  Future<void> _loadNews() async {
    try {
      final newsDataSource = News();
      await newsDataSource.getNews(ref);
      articles = newsDataSource.news
          .where(
            (article) =>
                article.urlToImage != null && article.urlToImage!.isNotEmpty,
          )
          .toList();
    } catch (e) {
      print('Error fetching news: $e');
      _errorMessage = 'Failed to load news. Please try again.';
    }
  }

  void _updateLoadingState() {
    if (mounted) {
      setState(() => _newsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        child: const CircleAvatar(radius: 20),
                        onTap: () {
                          context.push('/profile');
                        },
                      ),
                    ),
                    SvgPicture.asset(
                      'images/neqat_logo/logo-color.svg',
                      height: 30.0,
                      width: 30.0,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        ref.read(navigationProvider.notifier).goToPage(3);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),
                _newsLoading
                    ? _buildShimmerLoading(context)
                    : _buildHomeContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SectionSpacer(height: 16),
          CategoryList(categories: categories),
          const SectionSpacer(),
          TopNewsSection(
            sliders: sliders,
            activeIndex: _activeIndex,
            onPageChanged: (index) => setState(() => _activeIndex = index),
          ),
          const SectionSpacer(),
          TrendingNewsSection(articles: articles),
        ],
      ),
    );
  }
}

// -------------------------------
// Reusable Components
// -------------------------------

class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    // Removed const from text widgets so we can use Theme.of(context)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Current on ", style: Theme.of(context).textTheme.titleMedium),
        Text(
          "Neqat",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class SectionSpacer extends StatelessWidget {
  final double height;
  const SectionSpacer({this.height = 30, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}

class CategoryList extends StatelessWidget {
  final List<CategoryModel> categories;
  const CategoryList({required this.categories, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          // Use the updated CategoryTile that does NOT show an image.
          return CategoryTile(categoryName: categories[index].name!);
        },
      ),
    );
  }
}

/// Updated CategoryTile without image.
class CategoryTile extends StatelessWidget {
  final String categoryName;
  const CategoryTile({required this.categoryName, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _navigateToCategory(context),
        child: Container(
          decoration: BoxDecoration(
            // Use a subtle tint from the primary color.
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                categoryName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCategory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CategoryNews(name: categoryName)),
    );
  }
}

class TopNewsSection extends StatelessWidget {
  final List<SliderModel> sliders;
  final int activeIndex;
  final ValueChanged<int> onPageChanged;

  const TopNewsSection({
    required this.sliders,
    required this.activeIndex,
    required this.onPageChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: "Top News", viewAllRoute: "Top"),
        const SizedBox(height: 10),
        sliders.isEmpty
            ? Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('No top news available'),
                ),
              )
            : CarouselSlider.builder(
                itemCount: sliders.length,
                itemBuilder:
                    (context, index, _) => NewsSliderItem(
                      imageUrl: sliders[index].urlToImage ?? '',
                      title: sliders[index].title ?? 'Untitled',
                      onTap: () => _handleSliderTap(context, index),
                    ),
                options: CarouselOptions(
                  height: 200,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  onPageChanged: (index, _) => onPageChanged(index),
                ),
              ),
        const SizedBox(height: 16),
        if (sliders.isNotEmpty)
          PageIndicator(count: sliders.length, activeIndex: activeIndex),
      ],
    );
  }

  void _handleSliderTap(BuildContext context, int index) {
    if (index < sliders.length && sliders[index].url != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleView(blogUrl: sliders[index].url!),
        ),
      );
    }
  }
}

class TrendingNewsSection extends StatelessWidget {
  final List<ArticleModel> articles;
  const TrendingNewsSection({required this.articles, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: "Trending News", viewAllRoute: "Trending"),
        const SizedBox(height: 10),
        articles.isEmpty
            ? SizedBox(
              height: 200,
              child: const Center(child: Text('No trending news available')),
            )
            : ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: articles.length > 15 ? 15 : articles.length,
              itemBuilder:
                  (context, index) => BlogTile(article: articles[index]),
            ),
      ],
    );
  }
}

// -------------------------------
// Individual Components
// -------------------------------

class SectionHeader extends StatelessWidget {
  final String title;
  final String viewAllRoute;
  const SectionHeader({
    required this.title,
    required this.viewAllRoute,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllNews(news: viewAllRoute),
                  ),
                ),
            child: Text(
              "View all",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NewsSliderItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final VoidCallback onTap;

  const NewsSliderItem({
    required this.imageUrl,
    required this.title,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(children: [_buildImage(context), _buildTitleOverlay(context)]),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl.isNotEmpty 
          ? ProxiedNetworkImage(
              imageUrl: imageUrl,
              height: 200,
              fit: BoxFit.cover,
              width: double.infinity,
              useCache: true,
              placeholder: ShimmerLoading(child: Container(color: Colors.grey)),
              errorBuilder: (context, url, error) => Container(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                child: const Icon(Icons.error, size: 40),
              ),
            )
          : Container(
              height: 200,
              width: double.infinity,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              child: const Icon(Icons.image_not_supported, size: 40),
            ),
    );
  }

  Widget _buildTitleOverlay(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
          color: Colors.black.withOpacity(0.4),
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class PageIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const PageIndicator({
    required this.count,
    required this.activeIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) => _buildDot(index, context)),
    );
  }

  Widget _buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: index == activeIndex ? 20 : 10,
      height: 10,
      decoration: BoxDecoration(
        color:
            index == activeIndex
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

// -------------------------------
// Shimmer Loading Effect
// -------------------------------

class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
      highlightColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
      child: child,
    );
  }
}

Widget _buildShimmerLoading(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      children: [
        // Categories Shimmer
        ShimmerLoading(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              itemBuilder:
                  (_, __) => Container(
                    width: 120,
                    height: 70,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Breaking News Shimmer
        ShimmerLoading(
          child: Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Trending News Shimmer
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder:
              (_, __) => ShimmerLoading(
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 120,
                          height: 120,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: 15,
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                height: 15,
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: 15,
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.3,
                                height: 15,
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ],
    ),
  );
}
