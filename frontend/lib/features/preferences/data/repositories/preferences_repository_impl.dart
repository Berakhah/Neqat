import 'dart:io';

import 'package:frontend/shared/domain/utils/either.dart';
import 'package:frontend/shared/domain/error/failure.dart';

import '../../domain/entities/tag.dart';
import '../../domain/entities/user_preference.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../datasources/preferences_api_service.dart';
import '../models/preference_update.dart';
import '../models/tag_model.dart';
import '../models/user_preference_model.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  final PreferencesApiService _apiService;

  PreferencesRepositoryImpl({required PreferencesApiService apiService})
      : _apiService = apiService;

  @override
  Future<Either<Failure, List<Tag>>> getTags() async {
    try {
      final tags = await _apiService.getTags();
      return Right(tags);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserPreference>>> getUserPreferences() async {
    try {
      final preferences = await _apiService.getUserPreferences();
      return Right(preferences);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserPreference>>> updatePreferences(
      List<Map<String, dynamic>> updates) async {
    try {
      // Convert the updates to PreferenceUpdate objects
      final preferenceUpdates = updates.map((update) => PreferenceUpdate(
            tagId: update['tagId'],
            preferenceLevel: update['preferenceLevel'],
          )).toList();

      // Send the updates to the API
      final updatedPreferences = await _apiService.updatePreferences(preferenceUpdates);
      
      // Convert the response to UserPreference objects
      final preferences = updatedPreferences.map((json) {
        final tagModel = TagModel(
          id: json['tag_id'],
          name: json['tag_name'] ?? 'Unknown',
          description: null,
        );
        
        return UserPreferenceModel(
          id: json['id'],
          tag: tagModel,
          preferenceLevel: json['preference_level'],
          createdAt: DateTime.now(), // Not provided in the response
          updatedAt: DateTime.now(), // Not provided in the response
        );
      }).toList();
      
      return Right(preferences);
    } on SocketException {
      return Left(NetworkFailure(message: 'No internet connection'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
} 