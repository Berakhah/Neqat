import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/application/data_sources/show_category_news.dart';
import 'package:frontend/domain/entities/article_model.dart';
import 'package:frontend/domain/entities/show_category_model.dart';
import 'package:frontend/presentation/widgets/blog_tile.dart';
import 'package:shimmer/shimmer.dart';

class CategoryNews extends ConsumerStatefulWidget {
  final String name;
  const CategoryNews({super.key, required this.name});

  @override
  ConsumerState<CategoryNews> createState() => _CategoryNewsState();
}

class _CategoryNewsState extends ConsumerState<CategoryNews> {
  List<ShowCategoryModel> categories = [];
  bool _newsLoading = true;

  @override
  void initState() {
    super.initState();
    getCategories();
  }

  Future<void> getCategories() async {
    final categoryNews = ShowCategoryNews();
    await categoryNews.getCategoryNews(widget.name.toLowerCase(), ref);
    setState(() {
      categories = categoryNews.categories;
      _newsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text(
          widget.name,
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
          itemCount: _newsLoading ? 5 : categories.length,
          itemBuilder: (context, index) {
            if (_newsLoading) {
              return Shimmer.fromColors(
                baseColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.2),
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
                    const SizedBox(height: 10),
                  ],
                ),
              );
            } else {
              final article = ArticleModel(
                author: categories[index].author,
                content: categories[index].content,
                title: categories[index].title,
                description: categories[index].description,
                url: categories[index].url,
                urlToImage: categories[index].urlToImage,
              );
              return BlogTile(article: article);
            }
          },
        ),
      ),
    );
  }
}
