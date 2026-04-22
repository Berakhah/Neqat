import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/application/data_sources/category_list.dart';
import 'package:frontend/application/data_sources/show_search_news.dart';
import 'package:frontend/application/data_sources/slider_data.dart';
import 'package:frontend/domain/entities/article_model.dart';
import 'package:frontend/domain/entities/category_model.dart';
import 'package:frontend/domain/entities/search_model.dart';
import 'package:frontend/domain/entities/slider_model.dart';
import 'package:frontend/presentation/screens/article_view.dart';
import 'package:frontend/presentation/widgets/blog_tile.dart';
import 'package:shimmer/shimmer.dart';
import 'package:frontend/l10n/app_localizations.dart'; // Add this import

class SearchNews extends ConsumerStatefulWidget {
  String news; // "Top" for top headlines, otherwise search query
  SearchNews({super.key, required this.news});

  @override
  ConsumerState<SearchNews> createState() => _SearchNewsState();
}

class _SearchNewsState extends ConsumerState<SearchNews> {
  List<CategoryModel> categories = [];
  List<SliderModel> sliders = [];
  List<ShowSearchModel> articles = [];
  bool _newsLoading = true;
  String _searchQuery = '';
  String? _originalQuery;
  List<String>? _stemmedQuery;
  int? _totalNewsCount;
  int? _totalTelCount;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    categories = getCategories();
    _searchQuery = widget.news == "Top" ? '' : widget.news;
    _searchController.text = _searchQuery;
    if (widget.news == "Top") {
      getSliders();
    } else {
      getNews();
    }
  }

  Future<void> getNews() async {
    setState(() {
      _newsLoading = true;
    });
    try {
      final showSearch = ShowSearchNews();
      await showSearch.getSearchNews(Search: _searchQuery, ref: ref);
      _originalQuery = showSearch.originalQuery;
      _stemmedQuery = showSearch.stemmedQuery;
      _totalNewsCount = showSearch.newsCount;
      _totalTelCount = showSearch.telegramCount;

      articles =
          showSearch.searches.where((a) {
            if (a.type == 'telegram') return true;
            return a.urlToImage?.isNotEmpty ?? false;
          }).toList();

      if (articles.isEmpty) {
        print(
          'No articles or Telegram messages found for query: $_searchQuery',
        );
      } else {
        print('Fetched ${articles.length} items');
      }
    } catch (e) {
      print('Error fetching news or Telegram messages: $e');
    }
    setState(() {
      _newsLoading = false;
      widget.news = 'not top';
    });
  }

  Future<void> getSliders() async {
    final sliderData = Sliders();
    await sliderData.getSliders(ref);
    sliders = sliderData.sliders;
    setState(() {
      _newsLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildSearchAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Access AppLocalizations
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      iconTheme: Theme.of(context).appBarTheme.iconTheme,
      centerTitle: true,
      elevation: 0.0,
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          onEditingComplete: () {
            getNews();
          },
          decoration: InputDecoration(
            hintText: l10n.searchNewsHint,
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Access AppLocalizations
    return Scaffold(
      appBar: _buildSearchAppBar(context),
      body:
          _newsLoading
              ? _buildShimmerList()
              : articles.isEmpty && sliders.isEmpty
              ? Center(child: Text(l10n.noNewsOrMessagesFound))
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ——— HEADER SHOWING STEMMING ———
                  if (_originalQuery != null || _stemmedQuery != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_originalQuery != null)
                                Text(
                                  l10n.originalQueryLabel(_originalQuery!),
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              if (_stemmedQuery != null)
                                Text(
                                  l10n.stemmedQueryLabel(_stemmedQuery!.join(", ")),
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(color: Colors.grey[700]),
                                ),
                              if (_totalNewsCount != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    l10n.totalArticlesLabel(_totalNewsCount!),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              if (_totalTelCount != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    l10n.totalTelegramMessagesLabel(_totalTelCount!),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ——— ACTUAL LIST ———
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount:
                          widget.news == "Top"
                              ? sliders.length
                              : articles.length,
                      itemBuilder: (context, index) {
                        if (widget.news == "Top") {
                          final slider = sliders[index];
                          final article = ArticleModel(
                            type: ArticleType.news,
                            author: slider.author ?? 'No Author',
                            content: slider.content ?? 'No content',
                            title: slider.title ?? 'No title',
                            description: slider.description ?? 'No description',
                            url: slider.url ?? '',
                            urlToImage: slider.urlToImage ?? '',
                          );
                          return BlogTile(article: article);
                        } else {
                          final searchItem = articles[index];
                          final article = ArticleModel(
                            type:
                                searchItem.type == 'telegram'
                                    ? ArticleType.telegram
                                    : ArticleType.news,
                            author:
                                searchItem.type == 'telegram'
                                    ? searchItem.senderId ?? 'Unknown'
                                    : searchItem.author ?? 'No Author',
                            content: searchItem.content ?? 'No content',
                            title:
                                searchItem.type == 'telegram'
                                    ? searchItem.channelName ??
                                        'Telegram Message'
                                    : searchItem.title ?? 'No title',
                            description:
                                searchItem.description ?? 'No description',
                            url: searchItem.url ?? '',
                            urlToImage: searchItem.urlToImage ?? '',
                          );
                          return BlogTile(article: article);
                        }
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          highlightColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.1),
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
      },
    );
  }
}