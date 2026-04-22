import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/domain/entities/content_flag.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart';

final unresolvedFlagsFutureProvider = FutureProvider<List<ContentFlag>>((ref) async {
  final getUnresolvedFlags = ref.watch(getUnresolvedFlagsProvider);
  final result = await getUnresolvedFlags.call();
  return result.fold((failure) => throw Exception(failure.message), (flags) => flags);
});

class ReportedContentPage extends ConsumerWidget {
  const ReportedContentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(unresolvedFlagsFutureProvider);
    final resolver = ref.read(resolveContentFlagProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Content'),
      ),
      body: flagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (flags) {
          if (flags.isEmpty) {
            return const Center(child: Text('No unresolved reports.'));
          }
          return ListView.separated(
            itemCount: flags.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final flag = flags[index];
              return ListTile(
                leading: Icon(flag.contentType == 'POST' ? Icons.article : Icons.comment, color: Colors.red),
                title: Text('${flag.contentType} #${flag.contentId}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reason: ${flag.reason}'),
                    if (flag.description != null && flag.description!.isNotEmpty)
                      Text('Description: ${flag.description}'),
                    Text('Reported by: ${flag.reportedBy}'),
                    Text('Reported at: ${flag.createdAt.toLocal()}'),
                  ],
                ),
                trailing: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Resolve'),
                  onPressed: () async {
                    final notes = await _showResolutionDialog(context);
                    if (notes != null) {
                      final result = await resolver.call(flagId: flag.id, notes: notes);
                      result.fold(
                        (failure) => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: ${failure.message}'), backgroundColor: Colors.red),
                        ),
                        (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Flag resolved!')),
                          );
                          // Refresh the list
                          ref.refresh(unresolvedFlagsFutureProvider);
                        },
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<String?> _showResolutionDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Report'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Resolution notes'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }
} 