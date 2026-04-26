import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:mp3tageditor/core/services/audio_editor_service.dart';
import 'package:mp3tageditor/core/services/file_picker_service.dart';
import 'package:mp3tageditor/core/services/purchase_service.dart';
import 'package:mp3tageditor/core/widgets/gradient_app_bar.dart';
import 'package:mp3tageditor/features/home/presentation/library_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(selectedFilesProvider);
    final audioService = ref.read(audioEditorServiceProvider);

    Future<void> requirePaidAccess() async {
      final remaining = await audioService.getRemainingFreeEdits();
      if (remaining != 0) return;

      if (!context.mounted) return;
      try {
        await RevenueCatUI.presentPaywallIfNeeded('premium');
        final newInfo = await audioService.purchaseService.getCustomerInfo();
        ref.read(customerInfoProvider.notifier).updateInfo(newInfo);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not load subscriptions at this time.'),
            ),
          );
        }
      }

      final updatedRemaining = await audioService.getRemainingFreeEdits();
      if (updatedRemaining == 0 && context.mounted) {
        return;
      }
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Mp3 Tagger',
        actions: [
          IconButton(
            icon: const Icon(Icons.star_rounded),
            onPressed: () async {
              await RevenueCatUI.presentPaywallIfNeeded('premium');
              final newInfo =
                  await audioService.purchaseService.getCustomerInfo();
              ref.read(customerInfoProvider.notifier).updateInfo(newInfo);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body:
          files.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor.withAlpha(25),
                      ),
                      child: Icon(
                        Icons.library_music_outlined,
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No audio files imported.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the button below to import your first audio file',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  final fileName = file.path.split('/').last;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await requirePaidAccess();
                          if (!context.mounted) return;
                          final remaining =
                              await audioService.getRemainingFreeEdits();
                          if (remaining == 0) return;
                          await context.push('/editor', extra: file.path);
                          if (context.mounted) {
                            // ignore: unused_result
                            ref.refresh(selectedFilesProvider);
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withAlpha(25),
                                  ),
                                  child: Icon(
                                    Icons.music_note_outlined,
                                    size: 28,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap to edit tags',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 18,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isImporting ? null : _handleImportClick,
        label:
            _isImporting
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text('Import Audio'),
        icon: _isImporting ? const SizedBox.shrink() : const Icon(Icons.add),
      ),
    );
  }

  Future<void> _handleImportClick() async {
    if (_isImporting) return;

    setState(() => _isImporting = true);

    try {
      final audioService = ref.read(audioEditorServiceProvider);

      // Check paid access
      final remaining = await audioService.getRemainingFreeEdits();
      if (remaining == 0) {
        if (!mounted) return;
        try {
          await RevenueCatUI.presentPaywallIfNeeded('premium');
          final newInfo = await audioService.purchaseService.getCustomerInfo();
          ref.read(customerInfoProvider.notifier).updateInfo(newInfo);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not load subscriptions at this time.'),
              ),
            );
          }
        }
        return;
      }

      // Check remaining free edits
      if (!mounted) return;
      final updatedRemaining = await audioService.getRemainingFreeEdits();
      if (updatedRemaining == 0) return;

      // Pick files
      final filePickerService = ref.read(filePickerServiceProvider);
      final files = await filePickerService.pickAudioFiles();

      if (files == null || files.isEmpty) return;

      // Import files
      final imported = await ref
          .read(selectedFilesProvider.notifier)
          .addFiles(files);

      if (imported.isNotEmpty) {
        await audioService.consumeFreeUse();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing audio: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }
}
