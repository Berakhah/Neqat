import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/preferences_api_service.dart';
import '../../data/repositories/preferences_repository_impl.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../../domain/usecases/get_tags.dart';
import '../../domain/usecases/get_user_preferences.dart';
import '../../domain/usecases/update_preferences.dart';

// API Service Provider
final preferencesApiServiceProvider = Provider<PreferencesApiService>((ref) {
  return PreferencesApiService();
});

// Repository Provider
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  final apiService = ref.watch(preferencesApiServiceProvider);
  return PreferencesRepositoryImpl(apiService: apiService);
});

// Use Case Providers
final getTagsProvider = Provider<GetTags>((ref) {
  final repository = ref.watch(preferencesRepositoryProvider);
  return GetTags(repository);
});

final getUserPreferencesProvider = Provider<GetUserPreferences>((ref) {
  final repository = ref.watch(preferencesRepositoryProvider);
  return GetUserPreferences(repository);
});

final updatePreferencesProvider = Provider<UpdatePreferences>((ref) {
  final repository = ref.watch(preferencesRepositoryProvider);
  return UpdatePreferences(repository);
});

// Personalized news provider
final personalizedNewsProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiService = ref.watch(preferencesApiServiceProvider);
  return await apiService.getPersonalizedNews();
}); 