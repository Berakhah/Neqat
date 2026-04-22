import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/theme/app_colors.dart';
import '../../../../core/presentation/widgets/app_bar_back_button.dart';
import '../../../../core/presentation/widgets/app_button.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../core/domain/entities/tag.dart';
import '../controllers/preferences_controller.dart';
import '../widgets/preference_slider.dart';

class PreferencesPage extends ConsumerStatefulWidget {
  static const routeName = '/preferences';

  const PreferencesPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  bool _hasChanges = false;
  final Map<String, int> _updatedPreferences = {};

  @override
  void initState() {
    super.initState();
    // Load data when page is opened
    Future.microtask(() {
      ref.read(tagsControllerProvider.notifier).loadTags();
      ref.read(preferencesControllerProvider.notifier).loadPreferences();
    });
  }

  void _updatePreference(String tagId, int value) {
    setState(() {
      _updatedPreferences[tagId] = value;
      _hasChanges = true;
    });
  }

  Future<void> _savePreferences() async {
    if (_updatedPreferences.isEmpty) return;

    final updates = _updatedPreferences.entries.map((entry) => {
      'tagId': entry.key,
      'preferenceLevel': entry.value,
    }).toList();

    await ref.read(preferencesControllerProvider.notifier)
        .updateMultiplePreferences(updates);

    setState(() {
      _hasChanges = false;
      _updatedPreferences.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsState = ref.watch(tagsControllerProvider);
    final preferencesState = ref.watch(preferencesControllerProvider);
    
    final isLoading = tagsState.isLoading || preferencesState.isLoading;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Preferences'),
        leading: const AppBarBackButton(),
      ),
      body: isLoading 
          ? _buildLoadingView()
          : _buildContentView(tagsState, preferencesState),
      bottomNavigationBar: _hasChanges 
          ? _buildSaveButton()
          : null,
    );
  }

  Widget _buildLoadingView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShimmerLoading(
            isLoading: true,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentView(TagsState tagsState, PreferencesState preferencesState) {
    if (tagsState.error != null) {
      return Center(child: Text('Error: ${tagsState.error}'));
    }
    
    if (preferencesState.error != null) {
      return Center(child: Text('Error: ${preferencesState.error}'));
    }
    
    if (tagsState.tags.isEmpty) {
      return const Center(child: Text('No tags available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Adjust your content preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Move the slider to customize how often you want to see content about each topic',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 24),
        ...tagsState.tags.map((tag) {
          final currentPreference = _updatedPreferences.containsKey(tag.id)
              ? _updatedPreferences[tag.id]!
              : preferencesState.getPreferenceForTag(tag.id);
              
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PreferenceSlider(
              tag: tag,
              preferenceLevel: currentPreference,
              onChanged: (value) => _updatePreference(tag.id, value),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AppButton(
          label: 'Save Preferences',
          onPressed: _savePreferences,
          isLoading: ref.watch(preferencesControllerProvider).isLoading,
        ),
      ),
    );
  }
} 