import 'package:frontend/domain/entities/category_model.dart';

List<CategoryModel> getCategories() {
  List<CategoryModel> category = [];

  CategoryModel categoryModel = CategoryModel();
  categoryModel.name = "business";
  categoryModel.image = "images/politics.png";
  category.add(categoryModel);

  categoryModel = CategoryModel();
  categoryModel.name = "entertainment";
  categoryModel.image = "images/entertainment.jpg";
  category.add(categoryModel);

  categoryModel = CategoryModel();
  categoryModel.name = "general";
  categoryModel.image = "images/general.jpg";
  category.add(categoryModel);

  categoryModel = CategoryModel();
  categoryModel.name = "health";
  categoryModel.image = "images/health.jpeg";
  category.add(categoryModel);

  categoryModel = CategoryModel();
  categoryModel.name = "science";
  categoryModel.image = "images/science.jpg";
  category.add(categoryModel);

  categoryModel = CategoryModel();
  categoryModel.name = "sports";
  categoryModel.image = "images/sports.png";
  category.add(categoryModel);

  categoryModel = CategoryModel();
  categoryModel.name = "technology";
  categoryModel.image = "images/technology.jpg";
  category.add(categoryModel);

  return category;
}