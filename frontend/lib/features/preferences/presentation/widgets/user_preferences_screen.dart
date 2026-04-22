import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tag.dart';
import '../controllers/preferences_controller.dart';

class UserPreferencesScreen extends ConsumerStatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  ConsumerState<UserPreferencesScreen> createState() =>
      _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends ConsumerState<UserPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    // Load tags and preferences when screen opens
    Future.microtask(() {
      ref.read(tagsControllerProvider.notifier).loadTags();
      ref.read(preferencesControllerProvider.notifier).loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tagsState = ref.watch(tagsControllerProvider);
    final preferencesState = ref.watch(preferencesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Preferences'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(tagsControllerProvider.notifier).loadTags();
          await ref
              .read(preferencesControllerProvider.notifier)
              .loadPreferences();
        },
        child: tagsState.isLoading || preferencesState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : tagsState.error != null || preferencesState.error != null
                ? Center(
                    child: Text(
                      tagsState.error ??
                          preferencesState.error ??
                          'Unknown error',
                      textAlign: TextAlign.center,
                    ),
                  )
                : tagsState.tags.isEmpty
                    ? const Center(child: Text('No tags available'))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Adjust your content preferences below',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your preferences help us personalize content for you',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: ListView.separated(
                                itemCount: tagsState.tags.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemBuilder: (context, index) {
                                  final tag = tagsState.tags[index];
                                  return _buildPreferenceSlider(
                                    tag,
                                    preferencesState
                                        .getPreferenceForTag(tag.id),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildPreferenceSlider(Tag tag, int preferenceLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tag.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$preferenceLevel%',
              style: TextStyle(
                fontSize: 14,
                color: _getColorForPreferenceLevel(preferenceLevel),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (tag.description != null && tag.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              tag.description!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getColorForPreferenceLevel(preferenceLevel),
            thumbColor: _getColorForPreferenceLevel(preferenceLevel),
          ),
          child: Slider(
            min: 1,
            max: 100,
            divisions: 99,
            value: preferenceLevel.toDouble(),
            onChanged: (value) {
              ref
                  .read(preferencesControllerProvider.notifier)
                  .updatePreference(tag.id, value.round());
            },
          ),
        ),
      ],
    );
  }

  Color _getColorForPreferenceLevel(int level) {
    if (level < 25) {
      return Colors.red;
    } else if (level < 50) {
      return Colors.orange;
    } else if (level < 75) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }
}
