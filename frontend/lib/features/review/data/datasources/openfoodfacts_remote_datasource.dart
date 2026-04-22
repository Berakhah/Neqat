import 'package:openfoodfacts/openfoodfacts.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> searchProducts(String query);
}

class OpenFoodFactsRemoteDataSource implements ProductRemoteDataSource {
  OpenFoodFactsRemoteDataSource() {
    // Required once at app start — sets UserAgent for OpenFoodFacts SDK
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'MyFlutterApp',
      version: '1.0.0',
      system: 'Flutter',
    );
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    final config = ProductSearchQueryConfiguration(
      parametersList: [
        SearchTerms(terms: [query]),
        const PageSize(size: 50),
      ],
      language: OpenFoodFactsLanguage.ENGLISH,
      fields: [
        ProductField.BARCODE,
        ProductField.NAME,
        ProductField.GENERIC_NAME,
        ProductField.BRANDS,
        ProductField.QUANTITY,
        ProductField.IMAGE_FRONT_URL,
        ProductField.IMAGE_FRONT_SMALL_URL,
        ProductField.CATEGORIES,
        ProductField.INGREDIENTS_TEXT,
        ProductField.ECOSCORE_GRADE,
        ProductField.NUTRIMENTS,
        ProductField.LABELS_TAGS,
      ],
      version: ProductQueryVersion.v3,
    );

    try {
      final result = await OpenFoodAPIClient.searchProducts(null, config);

      final products = result.products;
      if (products == null || products.isEmpty) return [];

      return products.map(ProductModel.fromOpenFoodFacts).toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }
}
