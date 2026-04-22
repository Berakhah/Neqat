import 'package:frontend/features/review/domain/entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> search(String query);
}
