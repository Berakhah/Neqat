import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/review/data/datasources/openfoodfacts_remote_datasource.dart';
import 'package:frontend/features/review/data/repositories/product_repository_impl.dart';
import 'package:frontend/features/review/domain/entities/product.dart';
import 'package:frontend/features/review/domain/usecases/fetch_product.dart';

class ProductController extends StateNotifier<AsyncValue<List<Product>>> {
  final SearchProducts searchProducts;

  ProductController(this.searchProducts) : super(const AsyncValue.data([]));

  Future<void> getProducts(String query) async {
    if (query.trim().isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final products = await searchProducts(query);
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final productControllerProvider =
    StateNotifierProvider<ProductController, AsyncValue<List<Product>>>((ref) {
      final dataSource = OpenFoodFactsRemoteDataSource();
      final repository = ProductRepositoryImpl(remoteDataSource: dataSource);
      final searchProducts = SearchProducts(repository);
      return ProductController(searchProducts);
    });
