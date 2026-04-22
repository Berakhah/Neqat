import 'package:openfoodfacts/openfoodfacts.dart' as off;
import '../../domain/entities/product.dart';

class ProductModel extends Product {
  ProductModel({
    super.id,
    super.productName,
    super.genericName,
    super.brands,
    super.quantity,
    super.imageFrontUrl,
    super.imageFrontSmallUrl,
    super.categories,
    super.ingredientsText,
    super.nutriscoreGrade,
    super.ecoscoreGrade,
    super.nutriments,
    super.labelsTags,
  });

  /// Converts OpenFoodFacts.Product → ProductModel → Product entity
  factory ProductModel.fromOpenFoodFacts(off.Product product) {
    return ProductModel(
      id: product.barcode,
      productName: product.productName,
      genericName: product.genericName,
      brands: product.brands,
      quantity: product.quantity,
      imageFrontUrl: product.imageFrontUrl,
      imageFrontSmallUrl: product.imageFrontSmallUrl,
      categories: product.categories,
      ingredientsText: product.ingredientsText,
      nutriments: product.nutriments,
      labelsTags: product.labelsTags,
    );
  }
}
