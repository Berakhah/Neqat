import 'package:frontend/features/review/data/datasources/openfoodfacts_remote_datasource.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Product>> search(String query) async {
    try {
      final List<ProductModel> models = await remoteDataSource.searchProducts(
        query,
      );
      return models;
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }
}
