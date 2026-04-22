import 'package:frontend/features/review/domain/entities/product.dart';
import 'package:frontend/features/review/domain/repositories/product_repository.dart';

class SearchProducts {
  final ProductRepository repository;

  SearchProducts(this.repository);

  Future<List<Product>> call(String query) async {
    return repository.search(query);
  }
}
