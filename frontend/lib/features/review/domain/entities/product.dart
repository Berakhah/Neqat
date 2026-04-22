import 'package:openfoodfacts/openfoodfacts.dart';

class Product {
  final String? id;
  final String? productName;
  final String? genericName;
  final String? brands;
  final String? quantity;
  final String? imageFrontUrl;
  final String? imageFrontSmallUrl;
  final String? categories;
  final String? ingredientsText;
  final String? nutriscoreGrade;
  final String? ecoscoreGrade;
  final Nutriments? nutriments;
  final List<String>? labelsTags;

  const Product({
    this.id,
    this.productName,
    this.genericName,
    this.brands,
    this.quantity,
    this.imageFrontUrl,
    this.imageFrontSmallUrl,
    this.categories,
    this.ingredientsText,
    this.nutriscoreGrade,
    this.ecoscoreGrade,
    this.nutriments,
    this.labelsTags,
  });
}
