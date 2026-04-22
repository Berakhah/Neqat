import 'package:frontend/domain/entities/category_model.dart';

List<CategoryModel> getCategories() {
  List<CategoryModel> category = [];

  CategoryModel categoryModel = CategoryModel();
  categoryModel.name = "Business";
  categoryModel.image = "images/politics.png";
  category.add(categoryModel);

  categoryModel = CategoryModel();
  categoryModel.name = "Entertainment";
  categoryModel.image = "images/entertainment.jpg";
  category.add(categoryModel);

  categoryModel = CategoryModel();
  categoryModel.name = "General";
  categoryModel.image = "images/general.jpg";
  category.add(categoryModel);

  categoryModel = CategoryModel();
  categoryModel.name = "Health";
  categoryModel.image = "images/health.jpeg";
  category.add(categoryModel);

  categoryModel = CategoryModel();
  categoryModel.name = "Science";
  categoryModel.image = "images/science.jpg";
  category.add(categoryModel);

  categoryModel = CategoryModel();
  categoryModel.name = "Sports";
  categoryModel.image = "images/sports.png";
  category.add(categoryModel);

  categoryModel = CategoryModel();
  categoryModel.name = "Technology";
  categoryModel.image = "images/technology.jpg";
  category.add(categoryModel);

  return category;
}
