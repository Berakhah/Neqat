import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/application/data_sources/category_list.dart';
import 'package:frontend/application/data_sources/show_search_news.dart';
import 'package:frontend/application/data_sources/slider_data.dart';
import 'package:frontend/domain/entities/article_model.dart';
import 'package:frontend/domain/entities/category_model.dart';
import 'package:frontend/domain/entities/search_model.dart';
import 'package:frontend/domain/entities/slider_model.dart';
import 'package:frontend/presentation/widgets/blog_tile.dart';
import 'package:shimmer/shimmer.dart';

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
    if (!mounted) return;
    
    setState(() {
      _newsLoading = true;
    });
    try {
      final showSearch = ShowSearchNews();
      await showSearch.getSearchNews(Search: _searchQuery, ref: ref);
      articles = showSearch.searches
          .where(
            (article) =>
                article.urlToImage != null && article.urlToImage!.isNotEmpty,
          )
          .toList();
      if (articles.isEmpty) {
        print('No articles found for query: $_searchQuery');
      } else {
        print('Fetched ${articles.length} articles');
      }
    } catch (e) {
      print('Error fetching news: $e');
    }
    
    if (mounted) {
    setState(() {
      _newsLoading = false;
      widget.news = 'not top';
    });
    }
  }

  Future<void> getSliders() async {
    final sliderData = Sliders();
    await sliderData.getSliders(ref);
    sliders = sliderData.sliders;
    
    if (mounted) {
    setState(() {
      _newsLoading = false;
    });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildSearchAppBar(BuildContext context) {
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
          decoration: const InputDecoration(
            hintText: "Search News",
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
    return Scaffold(
      appBar: _buildSearchAppBar(context),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: _newsLoading
            ? _buildShimmerList()
            : articles.isEmpty && sliders.isEmpty
                ? const Center(child: Text('No news found'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount:
                        widget.news == "Top" ? sliders.length : articles.length,
                    itemBuilder: (context, index) {
                      if (widget.news == "Top") {
                        final slider = sliders[index];
                        final article = ArticleModel(
                          author: slider.author ?? 'No Author',
                          content: slider.content ?? 'No content',
                          title: slider.title ?? 'No title',
                          description: slider.description ?? 'No description',
                          url: slider.url ?? '',
                          urlToImage: slider.urlToImage ?? '',
                        );
                        return BlogTile(article: article);
                      } else {
                        final searchArticle = articles[index];
                        final article = ArticleModel(
                          author: searchArticle.author ?? 'No Author',
                          content: searchArticle.content ?? 'No content',
                          title: searchArticle.title ?? 'No title',
                          description:
                              searchArticle.description ?? 'No description',
                          url: searchArticle.url ?? '',
                          urlToImage: searchArticle.urlToImage ?? '',
                        );
                        return BlogTile(article: article);
                      }
                    },
                  ),
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
