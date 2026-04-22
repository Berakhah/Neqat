import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/tag.dart';
import '../../domain/entities/user_preference.dart';
import '../../domain/usecases/get_tags.dart';
import '../../domain/usecases/get_user_preferences.dart';
import '../../domain/usecases/update_preferences.dart';
import '../../data/models/content_interaction.dart';
import '../../data/datasources/preferences_api_service.dart';
import '../providers/preferences_providers.dart';

// State classes
class TagsState {
  final bool isLoading;
  final List<Tag> tags;
  final String? error;

  TagsState({
    this.isLoading = false,
    this.tags = const [],
    this.error,
  });

  TagsState copyWith({
    bool? isLoading,
    List<Tag>? tags,
    String? error,
  }) {
    return TagsState(
      isLoading: isLoading ?? this.isLoading,
      tags: tags ?? this.tags,
      error: error,
    );
  }
}

class PreferencesState {
  final bool isLoading;
  final List<UserPreference> preferences;
  final String? error;

  PreferencesState({
    this.isLoading = false,
    this.preferences = const [],
    this.error,
  });

  PreferencesState copyWith({
    bool? isLoading,
    List<UserPreference>? preferences,
    String? error,
  }) {
    return PreferencesState(
      isLoading: isLoading ?? this.isLoading,
      preferences: preferences ?? this.preferences,
      error: error,
    );
  }

  // Helper to get preference level for a tag
  int getPreferenceForTag(String tagId) {
    final preference = preferences.firstWhere(
      (pref) => pref.tag.id == tagId,
      orElse: () => UserPreference(
        id: '',
        tag: Tag(id: tagId, name: ''),
        preferenceLevel: 50, // Default preference level
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return preference.preferenceLevel;
  }
}

// Controllers
final tagsControllerProvider = StateNotifierProvider<TagsController, TagsState>((ref) {
  final getTags = ref.watch(getTagsProvider);
  return TagsController(getTags);
});

class TagsController extends StateNotifier<TagsState> {
  final GetTags _getTags;

  TagsController(this._getTags) : super(TagsState());

  Future<void> loadTags() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getTags();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (tags) => state = state.copyWith(
        isLoading: false,
        tags: tags,
      ),
    );
  }
}

final preferencesControllerProvider = StateNotifierProvider<PreferencesController, PreferencesState>((ref) {
  final getUserPreferences = ref.watch(getUserPreferencesProvider);
  final updatePreferences = ref.watch(updatePreferencesProvider);
  return PreferencesController(getUserPreferences, updatePreferences);
});

class PreferencesController extends StateNotifier<PreferencesState> {
  final GetUserPreferences _getUserPreferences;
  final UpdatePreferences _updatePreferences;
  final PreferencesApiService _preferencesApiService = PreferencesApiService();
  final Logger _logger = Logger();

  PreferencesController(this._getUserPreferences, this._updatePreferences)
      : super(PreferencesState());

  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getUserPreferences();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (preferences) => state = state.copyWith(
        isLoading: false,
        preferences: preferences,
      ),
    );
  }

  Future<void> updatePreference(String tagId, int preferenceLevel) async {
    state = state.copyWith(isLoading: true, error: null);

    final updates = [
      {
        'tagId': tagId,
        'preferenceLevel': preferenceLevel,
      }
    ];

    final result = await _updatePreferences(updates);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (updatedPreferences) {
        // Create a new list with the updated preference
        final currentPrefs = List<UserPreference>.from(state.preferences);
        
        // Find and update the preference if it exists
        final index = currentPrefs.indexWhere((pref) => pref.tag.id == tagId);
        if (index >= 0) {
          // Replace the existing preference
          currentPrefs[index] = updatedPreferences.firstWhere(
            (pref) => pref.tag.id == tagId,
            orElse: () => currentPrefs[index],
          );
        } else {
          // Add the new preference
          currentPrefs.addAll(
            updatedPreferences.where((pref) => pref.tag.id == tagId)
          );
        }
        
        state = state.copyWith(
          isLoading: false,
          preferences: currentPrefs,
        );
      },
    );
  }

  Future<void> updateMultiplePreferences(List<Map<String, dynamic>> updates) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updatePreferences(updates);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (updatedPreferences) {
        // Create a new list with the updated preferences
        final currentPrefs = List<UserPreference>.from(state.preferences);
        
        for (final updatedPref in updatedPreferences) {
          final tagId = updatedPref.tag.id;
          
          // Find and update the preference if it exists
          final index = currentPrefs.indexWhere((pref) => pref.tag.id == tagId);
          if (index >= 0) {
            // Replace the existing preference
            currentPrefs[index] = updatedPref;
          } else {
            // Add the new preference
            currentPrefs.add(updatedPref);
          }
        }
        
        state = state.copyWith(
          isLoading: false,
          preferences: currentPrefs,
        );
      },
    );
  }

  // Track user viewing a piece of content
  Future<void> trackContentView(String contentType, String contentId) async {
    try {
      final interaction = ContentInteraction.view(contentType, contentId);
      await _preferencesApiService.recordContentInteraction(interaction);
    } catch (e) {
      _logger.e('Error tracking content view', error: e);
      // Silently fail - don't disrupt user experience for analytics
    }
  }

  // Track user liking a piece of content
  Future<void> trackContentLike(String contentType, String contentId) async {
    try {
      final interaction = ContentInteraction.like(contentType, contentId);
      await _preferencesApiService.recordContentInteraction(interaction);
    } catch (e) {
      _logger.e('Error tracking content like', error: e);
    }
  }

  // Track user bookmarking a piece of content
  Future<void> trackContentBookmark(String contentType, String contentId) async {
    try {
      final interaction = ContentInteraction.bookmark(contentType, contentId);
      await _preferencesApiService.recordContentInteraction(interaction);
    } catch (e) {
      _logger.e('Error tracking content bookmark', error: e);
    }
  }

  // Track user sharing a piece of content
  Future<void> trackContentShare(String contentType, String contentId) async {
    try {
      final interaction = ContentInteraction.share(contentType, contentId);
      await _preferencesApiService.recordContentInteraction(interaction);
    } catch (e) {
      _logger.e('Error tracking content share', error: e);
    }
  }

  // Track time spent on content
  Future<void> trackTimeSpent(String contentType, String contentId, double seconds) async {
    if (seconds < 1.0) return; // Don't record very short interactions
    
    try {
      final interaction = ContentInteraction.timeSpent(contentType, contentId, seconds);
      await _preferencesApiService.recordContentInteraction(interaction);
    } catch (e) {
      _logger.e('Error tracking content time spent', error: e);
    }
  }

  // Batch record multiple interactions (for efficiency when user was offline)
  Future<void> batchRecordInteractions(List<ContentInteraction> interactions) async {
    if (interactions.isEmpty) return;
    
    try {
      await _preferencesApiService.batchRecordInteractions(interactions);
    } catch (e) {
      _logger.e('Error batch recording interactions', error: e);
    }
  }

  // Load personalized news based on preferences and interactions
  Future<List<dynamic>> loadPersonalizedNews() async {
    try {
      return await _preferencesApiService.getPersonalizedNews();
    } catch (e) {
      _logger.e('Error loading personalized news', error: e);
      throw Exception('Failed to load personalized content');
    }
  }
} 