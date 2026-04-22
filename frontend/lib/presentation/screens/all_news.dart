import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/application/data_sources/category_list.dart';
import 'package:frontend/application/data_sources/news.dart';
import 'package:frontend/application/data_sources/slider_data.dart';
import 'package:frontend/domain/entities/article_model.dart';
import 'package:frontend/domain/entities/category_model.dart';
import 'package:frontend/domain/entities/slider_model.dart';
import 'package:frontend/presentation/screens/article_view.dart';
import 'package:frontend/presentation/widgets/blog_tile.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

class AllNews extends ConsumerStatefulWidget {
  final String news;
  const AllNews({super.key, required this.news});

  @override
  ConsumerState<AllNews> createState() => _AllNewsState();
}

class _AllNewsState extends ConsumerState<AllNews> {
  List<CategoryModel> categories = [];
  List<SliderModel> sliders = [];
  List<ArticleModel> articles = [];
  bool _newsLoading = true;

  @override
  void initState() {
    super.initState();
    categories = getCategories();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _newsLoading = true;
    });
    await Future.wait([getSliders(), getNews()]);
    setState(() {
      _newsLoading = false;
    });
  }

  Future<void> getSliders() async {
    final slider = Sliders();
    await slider.getSliders(ref);
    sliders = slider.sliders;
  }

  Future<void> getNews() async {
    final newsClass = News();
    await newsClass.getNews(ref);
    articles = newsClass.news
        .where(
          (article) =>
              article.urlToImage != null && article.urlToImage!.isNotEmpty,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Localize the category name
    String localizedCategory;
    switch (widget.news.toLowerCase()) {
      case 'top':
        localizedCategory = l10n.topCategory;
        break;
      case 'trending':
        localizedCategory = l10n.trendingCategory;
        break;
      case 'business':
        localizedCategory = l10n.businessCategory;
        break;
      case 'entertainment':
        localizedCategory = l10n.entertainmentCategory;
        break;
      case 'general':
        localizedCategory = l10n.generalCategory;
        break;
      case 'health':
        localizedCategory = l10n.healthCategory;
        break;
      case 'science':
        localizedCategory = l10n.scienceCategory;
        break;
      case 'sports':
        localizedCategory = l10n.sportsCategory;
        break;
      case 'technology':
        localizedCategory = l10n.technologyCategory;
        break;
      default:
        localizedCategory = widget.news; // Fallback to the original string
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text(
          l10n.newsTitle(localizedCategory),
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: _newsLoading
              ? 5
              : widget.news.toLowerCase() == l10n.topCategory.toLowerCase()
                  ? sliders.length
                  : articles.length,
          itemBuilder: (context, index) {
            if (_newsLoading) {
              return Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                highlightColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 200,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: 20,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: 20,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 20,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            } else {
              if (widget.news.toLowerCase() == l10n.topCategory.toLowerCase()) {
                final article = ArticleModel(
                  type: ArticleType.news,
                  title: sliders[index].title,
                  description: sliders[index].description,
                  url: sliders[index].url,
                  urlToImage: sliders[index].urlToImage,
                );
                return BlogTile(article: article);
              } else {
                return BlogTile(article: articles[index]);
              }
            }
          },
        ),
      ),
    );
  }
}