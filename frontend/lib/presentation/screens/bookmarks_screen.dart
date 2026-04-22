// lib/presentation/screens/bookmark_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/providers/bookmark_provider.dart';
import 'package:frontend/app/providers/navigation_provider.dart';
import 'package:frontend/presentation/widgets/blog_tile.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/domain/entities/article_model.dart';

class BookmarkScreen extends ConsumerStatefulWidget {
  const BookmarkScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends ConsumerState<BookmarkScreen> {
  @override
  Widget build(BuildContext context) {
    // Listen for tab changes; when index==4, invalidate so we refetch
    ref.listen<int>(navigationProvider, (previous, next) {
      if (next == 4) {
        ref.invalidate(bookmarkedArticlesProvider);
      }
    });

    final l10n = AppLocalizations.of(context)!;
    final articlesAsync = ref.watch(bookmarkedArticlesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.bookmarksTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: articlesAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.errorLoadingBookmarks,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (articles) {
          if (articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noBookmarksMessage,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: articles.length,
            itemBuilder: (context, i) {
              final ArticleModel article = articles[i];
              return BlogTile(
                article: article,
                onBookmarkTap: () async {
                  // Toggle off the bookmark
                  await ref
                      .read(bookmarkProvider(article.url!).notifier)
                      .toggleBookmark();
                  // Then invalidate to refresh the list
                  ref.invalidate(bookmarkedArticlesProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}
